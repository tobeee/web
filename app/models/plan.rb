class Plan < ActiveRecord::Base
  has_many :subscriptions, dependent: :restrict_with_exception
  has_many :payments

  validates :name, :value, :stripe_id, presence: true

  def description
    "#{self.name} - #{(money_value * 12).format} / yr"
  end

  def money_value
    Money.new(read_attribute(:value), 'GBP')
  end

  def value_with_discount(user)
    self.money_value - [user.discount / 12, self.money_value].min
  end

  scope :visible,     -> { where(visible: true).order('id asc').offset(1) }
  scope :all_visible, -> { where(visible: true).order('id asc') }

  def self.total_pledged
    # self.all.reduce(Money.new(0, 'GBP')) { |aggr, plan| aggr + plan.money_value * plan.subscriptions.active.count }
    Subscription.active.includes(:plan).reduce(Money.new(0, 'GBP')) { |aggr, subscription| aggr + subscription.plan.money_value }
  end
end
