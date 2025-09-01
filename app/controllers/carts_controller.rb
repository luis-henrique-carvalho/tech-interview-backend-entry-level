class CartsController < ApplicationController
  before_action :set_cart

  def show
    render json: format_cart_response(@cart)
  end

  def create
    product = Product.find(cart_params[:product_id])
    quantity = cart_params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = quantity

    if cart_item.save
      render json: format_cart_response(@cart), status: :created
    else
      render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_item
    product = Product.find(cart_params[:product_id])
    quantity_to_add = cart_params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity += quantity_to_add

    if cart_item.save
      render json: format_cart_response(@cart), status: :ok
    else
      render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def remove_item
    cart_item = @cart.cart_items.find_by(product_id: params[:product_id])

    if cart_item
      cart_item.destroy
      render json: format_cart_response(@cart), status: :ok
    else
      render json: { error: 'Produto não encontrado no carrinho.' }, status: :not_found
    end
  end

  private

  def set_cart
    session_id = session[:cart_id] || generate_session_id

    @cart = Cart.find_by(session_id: session_id, abandoned_at: nil)

    unless @cart
      @cart = Cart.create!(session_id: session_id, total_price: 0)

      session[:cart_id] = session_id
    end
  end

  def generate_session_id
    SecureRandom.uuid
  end

  def cart_params
    params.require(:cart).permit(:product_id, :quantity)
  end

  def format_cart_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.map do |item|
        {
          id: item.product_id,
          name: item.name,
          quantity: item.quantity,
          unit_price: item.price,
          total_price: item.total_price
        }
      end,
      total_price: cart.total_price
    }
  end
end
