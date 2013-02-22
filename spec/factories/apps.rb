FactoryGirl.define do
  factory :app do
    name "Foo"
    domains "foo.com"

    factory :app_with_key do
      after(:create) do |app, evaluator|
        app.keys << FactoryGirl.create(:key)
      end
    end
  end
end
