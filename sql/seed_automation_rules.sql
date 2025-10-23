INSERT INTO public.automation_rules (name, trigger_type, conditions, actions, is_active)
VALUES
  ('Брошенные корзины 24ч', 'cart_abandonment',
   '{"hours_since_last_activity": 24, "min_cart_value": 20}',
   '[{"type":"send_notification","target_audience":"abandoned_cart","message_template":"🛒 {name}, не забудьте о товарах в корзине!"}]',
   TRUE),
  ('Первый заказ - благодарность', 'customer_milestone',
   '{"milestone_type": "first_order"}',
   '[{"type":"send_notification","target_audience":"first_time_buyers","message_template":"🎉 Спасибо за первый заказ, {name}! Ждите следующих предложений!"}]',
   TRUE),
  ('VIP статус достигнут', 'customer_milestone',
   '{"milestone_type": "spending_threshold", "spending_amount": 500}',
   '[{"type":"send_personalized_offer","target_segment":"champions"}]',
   TRUE)
ON CONFLICT (name) DO NOTHING;

