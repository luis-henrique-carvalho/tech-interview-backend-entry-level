class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  delegate :name, :price, to: :product, prefix: false

  after_save :update_cart_total
  after_destroy :update_cart_total

  def total_price
    product.price * quantity
  end

  private

  def update_cart_total
    cart.calculate_total_price
  end
end
