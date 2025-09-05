# == Schema Information
#
# Table name: carts
#
#  id                  :bigint           not null, primary key
#  abandoned_at        :datetime
#  last_interaction_at :datetime
#  total_price         :decimal(17, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  session_id          :string
#
# Indexes
#
#  index_carts_on_abandoned_at  (abandoned_at)
#  index_carts_on_session_id    (session_id)
#
class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  scope :active, -> { where(abandoned_at: nil) }
  scope :abandoned, -> { where.not(abandoned_at: nil) }
  scope :inactive_for, ->(duration) { where(last_interaction_at: ..duration.ago) }
  scope :abandoned_for, ->(duration) { where(abandoned_at: ..duration.ago) }

  def calculate_total_price
    total = cart_items.sum { |item| item.total_price }

    self.update(total_price: total)
  end

  def abandoned?
    abandoned_at.present?
  end

  def active?
    abandoned_at.nil?
  end

  def mark_as_abandoned!
    update!(abandoned_at: Time.current)
  end
end
