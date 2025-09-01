class ChangeDefaultQuantityInCartItems < ActiveRecord::Migration[7.1]
  def change
    change_column_default :cart_items, :quantity, 0
  end
end
