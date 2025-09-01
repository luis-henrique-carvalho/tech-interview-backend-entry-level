class Product < ApplicationRecord
  validates_presence_of :name, :price
  validates_numericality_of :price, greater_than_or_equal_to: 0

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  has_many :cart_items, dependent: :destroy
  has_many :carts, through: :cart_items
end
