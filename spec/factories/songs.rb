FactoryBot.define do
  factory :song do
    sequence(:title) { |n| "Song #{n}" }
    association :artist

    transient do
      genre_names { [] }
    end

    after(:build) do |song, evaluator|
      Array(evaluator.genre_names).each do |raw|
        song.genres << Genre.find_or_create_by_name!(raw)
      end
    end
  end
end
