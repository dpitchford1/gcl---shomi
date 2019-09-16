desc "Save default profile states into admin feature flags"
task :seed_default_profile_states  => :environment do

  if Admin::FeatureFlag.find(title: 'basic_redemption_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'basic_redemption_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"free","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"0","level":"promo"',
               'promo_data' => '"promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"',
               'promo_code_history' => '"promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"'}
    flag.options = options
    flag.save
  end
  # Note: you can manually edit the feature flags through the admin/feature_flags with the below options
  #address     = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"free","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"0","level":"promo"
  #promo_data  =  "promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"

  if Admin::FeatureFlag.find(title: 'premium_redemption_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'premium_redemption_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"free","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"1","level":"promo"',
               'promo_data' => '"promo_code":"premiumblue","promo_type":"TermSubscription","promo_desc":"Premium redemption NI"',
               'promo_code_history' => '"promo_code":"premiumblue","promo_type":"TermSubscription","promo_desc":"Premium redemption NI"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"free","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"1","level":"promo"
  #promo_data =  "promo_code":"premiumblue","promo_type":"TermSubscription","promo_desc":"Premium redemption NI"

  if Admin::FeatureFlag.find(title: 'topup_redemption_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'topup_redemption_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"TopUp","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"-|-"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"1","level":"promotopup"',
               'promo_data' => '"promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"',
               'promo_code_history' => '"promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"TopUp","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"-|-"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"1","level":"promotopup"
  #promo_data =  "promo_code":"supremebasic","promo_type":"TermSubscription","promo_desc":"Basic redemption NI"

  if Admin::FeatureFlag.find(title: 'basic_etf_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'basic_etf_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"0","level":"promo"',
               'promo_data' => '"promo_code":"bonus30","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 30"',
               'promo_code_history' => '"promo_code":"bonus30","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 30"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"0","level":"promo"
  #promo_data =  "promo_code":"bonus30","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 30"

  if Admin::FeatureFlag.find(title: 'premium_etf_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'premium_etf_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"1","level":"promo"',
               'promo_data' => '"promo_code":"bonus60","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 60"',
               'promo_code_history' => '"promo_code":"bonus60","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 60"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"1","level":"promo"
  #promo_data =  "promo_code":"bonus60","promo_type":"ExtendedTrial","promo_desc":"Extended free trial 60"

  if Admin::FeatureFlag.find(title: 'basic_discount_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'basic_discount_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"0","level":"promo"',
               'promo_data' => '"promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"',
               'promo_code_history' => '"promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"New","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"0","level":"promo"
  #promo_data =  "promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"

  if Admin::FeatureFlag.find(title: 'premium_discount_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'premium_discount_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"1","level":"promo"',
               'promo_data' => '"promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"',
               'promo_code_history' => '"promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"'}
    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 17:36:22 GMT 2015","order_id":"2c92c0f84e777fbd014e92c9e6fe6482","offer_id":"2c92c0f94a140541014a312950ae4b0d|2c92c0f84a13f41f014a31295f53557b","billing_option":"cc","billing_account":"","billing_amount":"14.99","taxes":"0.0","desc_en":"Includes unlimited access to 100+ of the world?s most-loved magazines PLUS unlimited access to popular weekly titles including Time, US Weekly,  Maclean?s , The New Yorker, Hello! Canada and more.","desc_fr":"Nextissue.ca-prime","status":"New","existing_offer_type":"Premium","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"1","level":"promo"
  #promo_data =  "promo_code":"2months50off","promo_type":"Discount","promo_desc":"50% off for 3 months"

  if Admin::FeatureFlag.find(title: 'cancelled_state').first.nil?
    flag = Admin::FeatureFlag.new(title: 'cancelled_state')

    options = {'address' => '"street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"',
               'user_orders' => '"product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"Cancelled","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"',
               'entitlement' => '"code":"NA","level":"ineligible"'}

    flag.options = options
    flag.save
  end
  #address = "street":"123 addr","address2":"","city":"toronto","province":"Ontario","postal_code":"a1b2c3"
  #user_orders = "product":"nextissue","order_date":"Wed Jul 15 08:00:00 GMT 2015","order_id":"2c92c0f84e777fbd014e92c5f88e5579","offer_id":"2c92c0f94a140541014a312950c64b10|2c92c0f84a13f41f014a31295f81557f","billing_option":"cc","billing_account":"","billing_amount":"9.99","taxes":"0.0","desc_en":"Unlimited access to 100+ of the world?s most-loved magazines including Sports Illustrated, Chatelaine, Vanity Fair, InStyle and more.","desc_fr":"Nextissue.ca-de base","status":"Cancelled","existing_offer_type":"Basic","masked_cc":"************4444","full_name":"br   14","activation_date":"Thu Jul 16 08:00:00 GMT 2015"
  #entitlement = "code":"NA","level":"ineligible"
end