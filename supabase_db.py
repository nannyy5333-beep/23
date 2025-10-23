
from urllib.parse import urlparse
import os, logging

def normalize_supabase_url(u: str | None) -> str | None:
    if not u: return None
    u = u.strip().strip('"').strip("'")
    while u.endswith('/'):
        u = u[:-1]
    for suffix in ("/rest/v1","/auth/v1","/storage/v1","/realtime/v1","/functions/v1"):
        if u.endswith(suffix):
            u = u[:-len(suffix)]
            while u.endswith('/'):
                u = u[:-1]
    return u

def assert_valid_supabase_url(u: str | None) -> str:
    if not u:
        raise ValueError("SUPABASE_URL пуст. Укажите https://<ref>.supabase.co")
    p = urlparse(u)
    if p.scheme not in ("https","http"):
        raise ValueError("SUPABASE_URL должен начинаться с https://")
    if not p.netloc:
        raise ValueError("SUPABASE_URL: отсутствует хост")
    if p.path not in ("","/"):
        raise ValueError("SUPABASE_URL должен быть базовым без /rest/v1 и пр.")
    return u

from dotenv import load_dotenv, find_dotenv
load_dotenv()
# Also search upwards from CWD and sibling folders:
load_dotenv(find_dotenv(usecwd=True))
from pathlib import Path as _Path
load_dotenv((_Path(__file__).resolve().parent / '.env'))
load_dotenv((_Path(__file__).resolve().parent.parent / '.env'))
"""
Supabase database manager for Telegram shop bot
"""
import os
try:
    import psycopg
except Exception:
    import psycopg2 as psycopg
import logging
from supabase import create_client, Client
from typing import Optional, List, Dict, Any

class SupabaseManager:
    def __init__(self):
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_anon_key = os.getenv('SUPABASE_ANON_KEY')
        supabase_service_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

        # Only validate when actually running (not during import checks)
        check_env = os.getenv('CHECK_ENV_VARS', 'true').lower() == 'true'
        if check_env and (not supabase_url or not supabase_anon_key):
            raise ValueError("SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required")

        # Use dummy values for testing if not provided
        if not supabase_url:
            supabase_url = "https://example.supabase.co"
        if not supabase_anon_key:
            supabase_anon_key = "dummy_key"
        if not supabase_service_key:
            supabase_service_key = "dummy_service_key"

        # Regular client for user operations (respects RLS)
        supabase_url_norm = assert_valid_supabase_url(normalize_supabase_url(supabase_url))
        self.client: Client = create_client(supabase_url_norm, supabase_anon_key)

        # Admin client for operations that need to bypass RLS
        supabase_url_norm = assert_valid_supabase_url(normalize_supabase_url(supabase_url))
        self.admin_client: Client = create_client(supabase_url_norm, supabase_service_key)

        logging.info("Supabase clients initialized")

    def get_user_by_telegram_id(self, telegram_id: int) -> Optional[List]:
        try:
            # Use admin_client to bypass RLS for user lookup
            response = self.admin_client.table('users').select('*').eq('telegram_id', telegram_id).execute()
            if response.data:
                # Convert dict to tuple for backward compatibility
                # Expected format: (id, telegram_id, name, phone, email, language, is_admin, created_at, is_registered)
                user = response.data[0]
                return [(
                    user.get('id'),
                    user.get('telegram_id'),
                    user.get('name'),
                    user.get('phone'),
                    user.get('email'),
                    user.get('language', 'ru'),
                    user.get('is_admin', False),
                    user.get('created_at'),
                    user.get('is_registered', False)
                )]
            return None
        except Exception as e:
            logging.error(f"Error getting user by telegram_id: {e}")
            return None

    def add_user(self, telegram_id: int, name: str, phone: Optional[str] = None,
                 email: Optional[str] = None, language: str = 'ru') -> Optional[str]:
        try:
            existing = self.get_user_by_telegram_id(telegram_id)
            if existing:
                return existing[0][0]  # Return user id (first element of tuple)

            # Use admin_client to bypass RLS for user registration
            response = self.admin_client.table('users').insert({
                'telegram_id': telegram_id,
                'name': name,
                'phone': phone,
                'email': email,
                'language': language
            }).execute()

            return response.data[0]['id'] if response.data else None
        except Exception as e:
            # Handle duplicate key error (user already exists)
            error_str = str(e)
            if 'duplicate key' in error_str or '23505' in error_str:
                logging.info(f"User {telegram_id} already exists, fetching existing user")
                existing = self.get_user_by_telegram_id(telegram_id)
                return existing[0][0] if existing else None

            logging.error(f"Error adding user: {e}")
            return None

    def mark_user_registered(self, telegram_id: int, phone: Optional[str] = None) -> bool:
        try:
            self.admin_client.rpc('mark_user_registered', {
                'p_telegram_id': telegram_id,
                'p_phone': phone
            }).execute()
            return True
        except Exception as e:
            logging.error(f"Error marking user as registered: {e}")
            return False

    def get_categories(self) -> Optional[List]:
        try:
            response = self.admin_client.table('categories').select('*').eq('is_active', True).order('name').execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, description, emoji, is_active, created_at)
                result = []
                for cat in response.data:
                    result.append((
                        cat.get('id'),
                        cat.get('name'),
                        cat.get('description'),
                        cat.get('emoji', '📦'),
                        cat.get('is_active', True),
                        cat.get('created_at')
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting categories: {e}")
            return None

    def get_products_by_category(self, category_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('subcategories').select(
                'id, name, emoji, products(count)'
            ).eq('category_id', category_id).eq('is_active', True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, emoji)
                result = []
                for sub in response.data:
                    result.append((
                        sub.get('id'),
                        sub.get('name'),
                        sub.get('emoji', '📦')
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting products by category: {e}")
            return None

    def get_products_by_subcategory(self, subcategory_id: str, limit: int = 10, offset: int = 0) -> Optional[List]:
        try:
            response = self.admin_client.table('products').select('*').eq(
                'subcategory_id', subcategory_id
            ).eq('is_active', True).order('name').range(offset, offset + limit - 1).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, description, price, image_url, category_id, subcategory_id, stock, is_active)
                result = []
                for product in response.data:
                    result.append((
                        product.get('id'),
                        product.get('name'),
                        product.get('description'),
                        float(product.get('price', 0)),
                        product.get('image_url'),
                        product.get('category_id'),
                        product.get('subcategory_id'),
                        product.get('stock', 0),
                        product.get('is_active', True)
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting products by subcategory: {e}")
            return None

    def get_product_by_id(self, product_id: str) -> Optional[tuple]:
        try:
            response = self.admin_client.table('products').select('*').eq('id', product_id).maybeSingle().execute()

            if response.data:
                product = response.data
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, description, price, image_url, category_id, subcategory_id, stock, is_active)
                return (
                    product.get('id'),
                    product.get('name'),
                    product.get('description'),
                    float(product.get('price', 0)),
                    product.get('image_url'),
                    product.get('category_id'),
                    product.get('subcategory_id'),
                    product.get('stock', 0),
                    product.get('is_active', True)
                )
            return None
        except Exception as e:
            logging.error(f"Error getting product by id: {e}")
            return None

    def add_to_cart(self, user_id: str, product_id: str, quantity: int = 1) -> Optional[str]:
        try:
            product = self.get_product_by_id(product_id)
            if not product or product['stock'] < quantity:
                return None

            existing_response = self.admin_client.table('cart').select('id, quantity').eq(
                'user_id', user_id
            ).eq('product_id', product_id).maybeSingle().execute()

            if existing_response.data:
                new_quantity = existing_response.data['quantity'] + quantity
                if new_quantity > product['stock']:
                    return None

                self.admin_client.table('cart').update({
                    'quantity': new_quantity
                }).eq('id', existing_response.data['id']).execute()
                return existing_response.data['id']
            else:
                response = self.admin_client.table('cart').insert({
                    'user_id': user_id,
                    'product_id': product_id,
                    'quantity': quantity
                }).execute()
                return response.data[0]['id'] if response.data else None
        except Exception as e:
            logging.error(f"Error adding to cart: {e}")
            return None

    def get_cart_items(self, user_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('cart').select(
                'id, quantity, products(id, name, price, image_url)'
            ).eq('user_id', user_id).order('created_at', desc=True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (cart_id, product_name, price, quantity, product_id, image_url)
                result = []
                for item in response.data:
                    product = item.get('products', {})
                    result.append((
                        item.get('id'),
                        product.get('name'),
                        float(product.get('price', 0)),
                        item.get('quantity'),
                        product.get('id'),
                        product.get('image_url')
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting cart items: {e}")
            return None

    def clear_cart(self, user_id: str) -> bool:
        try:
            self.admin_client.table('cart').delete().eq('user_id', user_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error clearing cart: {e}")
            return False

    def create_order(self, user_id: str, total_amount: float, delivery_address: str,
                     payment_method: str, latitude: Optional[float] = None,
                     longitude: Optional[float] = None) -> Optional[str]:
        try:
            response = self.admin_client.table('orders').insert({
                'user_id': user_id,
                'total_amount': total_amount,
                'delivery_address': delivery_address,
                'payment_method': payment_method,
                'latitude': latitude,
                'longitude': longitude
            }).execute()
            return response.data[0]['id'] if response.data else None
        except Exception as e:
            logging.error(f"Error creating order: {e}")
            return None

    def add_order_items(self, order_id: str, cart_items: List[Dict]) -> bool:
        try:
            items = []
            for item in cart_items:
                product = item.get('products')
                if product:
                    items.append({
                        'order_id': order_id,
                        'product_id': product['id'],
                        'quantity': item['quantity'],
                        'price': product['price']
                    })

            if items:
                self.admin_client.table('order_items').insert(items).execute()
            return True
        except Exception as e:
            logging.error(f"Error adding order items: {e}")
            return False

    def get_user_orders(self, user_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('orders').select('*').eq(
                'user_id', user_id
            ).order('created_at', desc=True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, user_id, total_amount, status, delivery_address, payment_method, payment_status, created_at, updated_at)
                result = []
                for order in response.data:
                    result.append((
                        order.get('id'),
                        order.get('user_id'),
                        float(order.get('total_amount', 0)),
                        order.get('status'),
                        order.get('delivery_address'),
                        order.get('payment_method'),
                        order.get('payment_status'),
                        order.get('created_at'),
                        order.get('updated_at')
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting user orders: {e}")
            return None

    def get_order_details(self, order_id: str) -> Optional[Dict]:
        try:
            order_response = self.admin_client.table('orders').select('*').eq('id', order_id).maybeSingle().execute()
            if not order_response.data:
                return None

            items_response = self.admin_client.table('order_items').select(
                'quantity, price, products(name, image_url)'
            ).eq('order_id', order_id).execute()

            return {
                'order': order_response.data,
                'items': items_response.data
            }
        except Exception as e:
            logging.error(f"Error getting order details: {e}")
            return None

    def update_order_status(self, order_id: str, status: str) -> bool:
        try:
            self.admin_client.table('orders').update({'status': status}).eq('id', order_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error updating order status: {e}")
            return False

    def search_products(self, query: str, limit: int = 10) -> Optional[List]:
        try:
            response = self.admin_client.table('products').select('*').or_(
                f'name.ilike.%{query}%,description.ilike.%{query}%'
            ).eq('is_active', True).order('name').limit(limit).execute()
            return response.data
        except Exception as e:
            logging.error(f"Error searching products: {e}")
            return None

    def add_review(self, user_id: str, product_id: str, rating: int, comment: str) -> Optional[str]:
        try:
            response = self.admin_client.table('reviews').insert({
                'user_id': user_id,
                'product_id': product_id,
                'rating': rating,
                'comment': comment
            }).execute()
            return response.data[0]['id'] if response.data else None
        except Exception as e:
            logging.error(f"Error adding review: {e}")
            return None

    def get_product_reviews(self, product_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('reviews').select(
                'rating, comment, created_at, users(name)'
            ).eq('product_id', product_id).order('created_at', desc=True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (rating, comment, created_at, user_name)
                result = []
                for review in response.data:
                    user = review.get('users', {})
                    result.append((
                        review.get('rating', 0),
                        review.get('comment'),
                        review.get('created_at'),
                        user.get('name') if user else 'Anonymous'
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting product reviews: {e}")
            return None

    def add_to_favorites(self, user_id: str, product_id: str) -> bool:
        try:
            self.admin_client.table('favorites').insert({
                'user_id': user_id,
                'product_id': product_id
            }).execute()
            return True
        except Exception as e:
            logging.error(f"Error adding to favorites: {e}")
            return False

    def remove_from_favorites(self, user_id: str, product_id: str) -> bool:
        try:
            self.admin_client.table('favorites').delete().eq('user_id', user_id).eq('product_id', product_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error removing from favorites: {e}")
            return False

    def get_user_favorites(self, user_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('favorites').select(
                'products(*)'
            ).eq('user_id', user_id).order('created_at', desc=True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, description, price, image_url, category_id, subcategory_id, stock, is_active)
                result = []
                for item in response.data:
                    product = item.get('products', {})
                    if product:
                        result.append((
                            product.get('id'),
                            product.get('name'),
                            product.get('description'),
                            float(product.get('price', 0)),
                            product.get('image_url'),
                            product.get('category_id'),
                            product.get('subcategory_id'),
                            product.get('stock', 0),
                            product.get('is_active', True)
                        ))
                return result
            return []
        except Exception as e:
            logging.error(f"Error getting user favorites: {e}")
            return None

    def add_notification(self, user_id: str, title: str, message: str, notification_type: str = 'info') -> Optional[str]:
        try:
            response = self.admin_client.table('notifications').insert({
                'user_id': user_id,
                'title': title,
                'message': message,
                'type': notification_type
            }).execute()
            return response.data[0]['id'] if response.data else None
        except Exception as e:
            logging.error(f"Error adding notification: {e}")
            return None

    def get_unread_notifications(self, user_id: str) -> Optional[List]:
        try:
            response = self.admin_client.table('notifications').select('*').eq(
                'user_id', user_id
            ).eq('is_read', False).order('created_at', desc=True).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, user_id, title, message, type, is_read, created_at)
                result = []
                for notif in response.data:
                    result.append((
                        notif.get('id'),
                        notif.get('user_id'),
                        notif.get('title'),
                        notif.get('message'),
                        notif.get('type', 'info'),
                        notif.get('is_read', False),
                        notif.get('created_at')
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting unread notifications: {e}")
            return None

    def mark_notification_read(self, notification_id: str) -> bool:
        try:
            self.admin_client.table('notifications').update({'is_read': True}).eq('id', notification_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error marking notification read: {e}")
            return False

    def get_user_loyalty_points(self, user_id: str) -> Optional[Dict]:
        try:
            response = self.admin_client.table('loyalty_points').select('*').eq('user_id', user_id).maybeSingle().execute()

            if not response.data:
                # Use admin_client to create initial loyalty_points record
                insert_response = self.admin_client.table('loyalty_points').insert({
                    'user_id': user_id
                }).execute()
                return insert_response.data[0] if insert_response.data else None

            return response.data
        except Exception as e:
            logging.error(f"Error getting user loyalty points: {e}")
            return None

    def update_loyalty_points(self, user_id: str, points_to_add: int) -> bool:
        try:
            response = self.admin_client.rpc('update_loyalty_points', {
                'p_user_id': user_id,
                'p_points': points_to_add
            }).execute()
            return True
        except Exception as e:
            current = self.get_user_loyalty_points(user_id)
            if current:
                self.admin_client.table('loyalty_points').update({
                    'current_points': current['current_points'] + points_to_add,
                    'total_earned': current['total_earned'] + points_to_add
                }).eq('user_id', user_id).execute()
                return True
            logging.error(f"Error updating loyalty points: {e}")
            return False

    def remove_from_cart(self, cart_item_id: str) -> bool:
        try:
            self.admin_client.table('cart').delete().eq('id', cart_item_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error removing from cart: {e}")
            return False

    def update_cart_quantity(self, cart_item_id: str, quantity: int) -> bool:
        try:
            if quantity <= 0:
                return self.remove_from_cart(cart_item_id)
            else:
                self.admin_client.table('cart').update({'quantity': quantity}).eq('id', cart_item_id).execute()
                return True
        except Exception as e:
            logging.error(f"Error updating cart quantity: {e}")
            return False

    def increment_product_views(self, product_id: str) -> bool:
        try:
            product = self.get_product_by_id(product_id)
            if product:
                self.admin_client.table('products').update({
                    'views': product['views'] + 1
                }).eq('id', product_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error incrementing product views: {e}")
            return False

    def get_popular_products(self, limit: int = 10) -> Optional[List]:
        try:
            response = self.admin_client.table('products').select('*').eq(
                'is_active', True
            ).order('views', desc=True).order('sales_count', desc=True).limit(limit).execute()

            if response.data:
                # Convert to tuple format for backward compatibility
                # Expected: (id, name, description, price, image_url, category_id, subcategory_id, stock, is_active)
                result = []
                for product in response.data:
                    result.append((
                        product.get('id'),
                        product.get('name'),
                        product.get('description'),
                        float(product.get('price', 0)),
                        product.get('image_url'),
                        product.get('category_id'),
                        product.get('subcategory_id'),
                        product.get('stock', 0),
                        product.get('is_active', True)
                    ))
                return result
            return None
        except Exception as e:
            logging.error(f"Error getting popular products: {e}")
            return None

    def update_user_language(self, user_id: str, language: str) -> bool:
        try:
            self.admin_client.table('users').update({'language': language}).eq('id', user_id).execute()
            return True
        except Exception as e:
            logging.error(f"Error updating user language: {e}")
            return False

    

    def _qualify_public_tables(self, query: str) -> str:
        """Add `public.` schema for known tables when not already qualified."""
        import re
        tables = [
            "users","orders","order_items","automation_rules","scheduled_posts","inventory_rules",
            "products","product_images","favorites","categories","subcategories","promo_codes",
            "promo_uses","shipments","loyalty_points","notifications","suppliers","business_expenses",
            "automation_executions","security_logs","webhook_logs","stock_reservations",
            "stocktaking_items","stocktaking_sessions","user_activity_logs","post_activity","post_statistics"
        ]
        def repl(m):
            kw = m.group(1)
            tbl = m.group(2)
            # if already schema-qualified, leave as is
            if "." in tbl:
                return m.group(0)
            if tbl.lower() in tables:
                return f"{kw} public.{tbl}"
            return m.group(0)
        # Handle FROM and JOIN
        query = re.sub(r"\b(FROM|JOIN)\s+([a-zA-Z_][a-zA-Z0-9_\.]+)", repl, query, flags=re.IGNORECASE)
        # Handle UPDATE, INSERT INTO, DELETE FROM
        query = re.sub(r"\b(UPDATE|INTO|DELETE\s+FROM)\s+([a-zA-Z_][a-zA-Z0-9_\.]+)", repl, query, flags=re.IGNORECASE)
        return query

    def _normalize_exec_sql_result(self, rpc_result, is_select: bool):
        """Normalize Supabase RPC exec_sql return shape.
        - For SELECT: returns a list of tuples (row-wise), preserving column order.
        - For others: returns the raw data or count.
        """
        try:
            data = getattr(rpc_result, 'data', rpc_result)
            # Handle [{'exec_sql': [...] }]
            if isinstance(data, list) and len(data) == 1 and isinstance(data[0], dict) and 'exec_sql' in data[0]:
                data = data[0]['exec_sql']
            if is_select:
                if data is None:
                    return []
                if isinstance(data, dict):
                    data = [data]
                if isinstance(data, list) and data and isinstance(data[0], dict):
                    ordered = []
                    for row in data:
                        try:
                            # Если есть 'id' — ставим его первым, остальное по порядку
                            if isinstance(row, dict) and 'id' in row:
                                keys = ['id'] + [k for k in row.keys() if k != 'id']
                                ordered.append(tuple(row[k] for k in keys))
                            else:
                                ordered.append(tuple(row.values()))
                        except Exception:
                            ordered.append(tuple(getattr(row, 'values', lambda: [])()))
                    return ordered

                if isinstance(data, list):
                    return [tuple(row) if isinstance(row, (list, tuple)) else (row,) for row in data]
                return [(data,)]
            else:
                return data
        except Exception:
            return [] if is_select else None
    
    def execute_query(self, query: str, params: tuple = None) -> Optional[List]:
            """
            Execute raw SQL query with Postgres syntax
            Converts SQLite-style queries to Postgres where needed
            Returns: List of tuples for SELECT, affected rows count for INSERT/UPDATE/DELETE
            """
            try:
                # Convert SQLite date functions to Postgres
                query = self._convert_sqlite_to_postgres(query)
                # Ensure public schema qualification
                query = self._qualify_public_tables(query)
    
                # Execute query
                if params:
                    # Use parameterized query with Supabase RPC if needed
                    # For now, simple string replacement (not secure for user input!)
                    for i, param in enumerate(params):
                        # Support both ? and %s placeholders
                        if '%s' in query:
                            placeholder = '%s'
                        elif '?' in query:
                            placeholder = '?'
                        else:
                            placeholder = f'${i+1}'
    
                        if placeholder in query:
                            if isinstance(param, str):
                                # Escape single quotes in strings
                                safe_param = param.replace("'", "''")
                                query = query.replace(placeholder, f"'{safe_param}'", 1)
                            elif isinstance(param, bool):
                                query = query.replace(placeholder, 'true' if param else 'false', 1)
                            elif param is None:
                                query = query.replace(placeholder, 'NULL', 1)
                            else:
                                query = query.replace(placeholder, str(param), 1)
    
                # Determine query type
                query_upper = query.strip().upper()
    
                if query_upper.startswith('SELECT'):
                    # Execute SELECT via RPC using admin client to bypass RLS
                    result = self.admin_client.rpc('exec_sql', {'sql': query}).execute()
                    return self._normalize_exec_sql_result(result, True)
    
                elif query_upper.startswith('INSERT'):
                    # Execute INSERT via RPC using admin client to bypass RLS
                    result = self.admin_client.rpc('exec_sql', {'sql': query}).execute()
                    # Return inserted row ID if available
                    return self._normalize_exec_sql_result(result, False)
    
                elif query_upper.startswith(('UPDATE', 'DELETE')):
                    # Execute UPDATE/DELETE via RPC using admin client to bypass RLS
                    result = self.admin_client.rpc('exec_sql', {'sql': query}).execute()
                    return self._normalize_exec_sql_result(result, False)
    
                else:
                    # Generic execution using admin client
                    result = self.admin_client.rpc('exec_sql', {'sql': query}).execute()
                    return self._normalize_exec_sql_result(result, False)
    
            except Exception as e:
                logging.error(f"Error executing query: {e}\nQuery: {query}")
                return None
    
    def _convert_sqlite_to_postgres(self, query: str) -> str:
        """Convert SQLite-specific syntax to Postgres"""
        import re

        # Convert date('now') -> CURRENT_DATE
        query = re.sub(r"date\('now'\)", "CURRENT_DATE", query, flags=re.IGNORECASE)

        # Convert NOW() -> NOW()
        query = re.sub(r"datetime\('now'\)", "NOW()", query, flags=re.IGNORECASE)

        # Convert (NOW() - INTERVAL '7 day') -> CURRENT_DATE - INTERVAL '7 days'
        query = re.sub(
            r"date\('now',\s*'([+-])(\d+)\s+days?'\)",
            lambda m: f"CURRENT_DATE {m.group(1)} INTERVAL '{m.group(2)} days'",
            query,
            flags=re.IGNORECASE
        )

        # Convert NOW() - INTERVAL '30 days' -> NOW() - INTERVAL '30 days'
        query = re.sub(
            r"datetime\('now',\s*'([+-])(\d+)\s+days?'\)",
            lambda m: f"NOW() {m.group(1)} INTERVAL '{m.group(2)} days'",
            query,
            flags=re.IGNORECASE
        )

        # Convert DATE(column) -> column::date
        query = re.sub(r"DATE\((\w+)\)", r"\1::date", query, flags=re.IGNORECASE)

        # Convert CURRENT_TIMESTAMP to NOW()
        query = re.sub(r"CURRENT_TIMESTAMP", "NOW()", query, flags=re.IGNORECASE)

        # (moved conversions are now inside the function)

        # Доп. конвертации: IFNULL -> COALESCE и булевы =1/0
        query = re.sub(r'\bIFNULL\s*\(', 'COALESCE(', query, flags=re.IGNORECASE)
        query = re.sub(r'\b(is_[a-z_]+|[a-z_]+_flag)\s*=\s*1\b', r'\1 = TRUE', query, flags=re.IGNORECASE)
        query = re.sub(r'\b(is_[a-z_]+|[a-z_]+_flag)\s*=\s*0\b', r'\1 = FALSE', query, flags=re.IGNORECASE)
        return query

    # === SAFE UPSERTS (service_role) ===
    def upsert_user(self, telegram_id: int, name: str, language: str,
                    phone: str | None = None, email: str | None = None):
        """
        Создаёт/обновляет пользователя через service_role (обходит RLS).
        Конфликт по telegram_id, безопасно обновляет только переданные поля.
        Возвращает dict (id, is_admin, language, is_registered) или None.
        """
        payload = {
            "telegram_id": telegram_id,
            "name": name,
            "language": language,
            "is_registered": True,
        }
        if phone is not None:
            payload["phone"] = phone
        if email is not None:
            payload["email"] = email
        try:
            res = self.admin_client.table("users") \
                .upsert(payload, on_conflict="telegram_id", ignore_duplicates=False) \
                .select("id, is_admin, language, is_registered") \
                .execute()
            return res.data[0] if res.data else None
        except Exception as e:
            logging.exception("upsert_user failed: %s", e)
            return None
    
    def create_or_promote_admin(self, telegram_id: int, name: str, language: str = "ru") -> bool:
        payload = {
            "telegram_id": telegram_id,
            "name": name,
            "language": language,
            "is_admin": True,
            "is_registered": True,
        }
        try:
            res = self.admin_client.table("users") \
                .upsert(payload, on_conflict="telegram_id", ignore_duplicates=False) \
                .select("id") \
                .execute()
            return bool(res.data)
        except Exception as e:
            logging.exception("create_or_promote_admin failed: %s", e)
            return False

    # === low-level PG executor (SELECT/DDL/DML) ===
    def _pg_exec(self, sql: str, params=None, fetch: bool=False):
        dsn = os.getenv("DATABASE_URL")
        if not dsn:
            raise RuntimeError("DATABASE_URL is not set")
        conn = psycopg.connect(dsn)
        try:
            with conn:
                with conn.cursor() as cur:
                    cur.execute(sql, params or None)
                    if fetch:
                        try:
                            return cur.fetchall()
                        except Exception:
                            return []
                    return []
        finally:
            try:
                conn.close()
            except Exception:
                pass
