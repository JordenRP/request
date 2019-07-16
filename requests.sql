create table accounts (
    id              serial primary key,
    created         date,
    trial_started   date,
    trial_ended     date,
    paid_started    date,
    paid_cancelled  date
  );
  
  create table orders (
    id              serial primary key,
    account_id      serial references accounts(id),
    amount          integer,
    currency        varchar(3),
    month           smallint,
    created         date
  );


SELECT s.sign_up AS "Sign Up",
       f.free AS "Free",
       t.trial AS "Trial",
       p.premium AS "Premium",
       pc.premium_churn AS "Premiun Churn"
FROM
( /*Новые аккаунты*/
  SELECT  count(*) AS sign_up
  FROM accounts
  WHERE date_part('month', created) = date_part('month', now())
) s,
( /*Количество бесплтных*/
  SELECT  count(*) AS free 
  FROM accounts
  WHERE paid_started is null
) f,
( /*Количество триальных*/
  SELECT  count(*) AS trial
  FROM accounts
  WHERE date_part('month', trial_started) = date_part('month', now())
  ) t,
( /*Количество новых платных подписок*/
  SELECT  count(*) AS premium
  FROM accounts
  WHERE date_part('month', paid_started) = date_part('month', now())
) p,
( /*Количество отмен платных подписок*/
  SELECT  count(*) AS premium_churn 
  FROM accounts
  WHERE date_part('month', paid_cancelled) = date_part('month', now())
) pc




SELECT e.mmr_eur + u.mmr_usd + r.mmr_rub AS "MMR",
       re.revenue_eur + ru.revenue_usd + rr.revenue_rub AS "Revenur"
FROM

( /* Запрос revenue в евро и перевод в рубли */
  SELECT sum(amount*70) AS revenue_eur
  FROM orders
  WHERE date_part('month', created) = date_part('month', now()) -- Отсеивание платежей за прошедшие месяцы
  AND currency = 'EUR'
) re,

( /* Запрос revenue в долларах и перевод в рубли */
  SELECT sum(amount*63) AS revenue_usd
  FROM orders
  WHERE date_part('month', created) = date_part('month', now()) -- Отсеивание платежей за прошедшие месяцы
  AND currency = 'USD'
) ru,

( /* Запрос revenue в рублях */
  SELECT sum(amount) AS revenue_rub
  FROM orders
  WHERE date_part('month', created) = date_part('month', now()) -- Отсеивание платежей за прошедшие месяцы
  AND currency = 'RUB'
) rr,

( /* Запрос MMR в евро и перевод в рубли */
  SELECT sum(o.amount/o.month)*70 AS mmr_eur
  FROM orders o
  JOIN accounts a
  ON o.account_id = a.id
  WHERE o.created = a.paid_started -- Отсеивание устаревших платежей 
  AND a.paid_cancelled >= now() -- Проверка актуальности подписки
  AND currency = 'EUR'
) e,

( /* Запрос MMR в долларах и перевод в рубли */
  SELECT sum(o.amount/o.month)*63 AS mmr_usd
  FROM orders o
  JOIN accounts a
  ON o.account_id = a.id
  WHERE o.created = a.paid_started -- Отсеивание устаревших платежей 
  AND a.paid_cancelled >= now() -- Проверка актуальности подписки
  AND currency = 'USD'
) u,

( /* Запрос MMR в рублях */
SELECT sum(o.amount/o.month) AS mmr_rub
FROM orders o
JOIN accounts a
ON o.account_id = a.id
WHERE o.created = a.paid_started -- Отсеивание устаревших платежей 
AND a.paid_cancelled >= now() -- Проверка актуальности подписки
AND currency = 'RUB'
) r