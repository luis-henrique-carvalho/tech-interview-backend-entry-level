class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    mark_abandoned_carts
    remove_old_abandoned_carts
  end

  private

  def mark_abandoned_carts
    abandoned_carts = Cart.active.inactive_for(3.hours)
    abandoned_carts.update_all(abandoned_at: Time.current)

    Rails.logger.info "Marked #{abandoned_carts.count} carts as abandoned"
  end

  def remove_old_abandoned_carts
    old_abandoned_carts = Cart.abandoned_for(7.days)
    old_abandoned_carts.destroy_all

    Rails.logger.info "Removed #{old_abandoned_carts.count} old abandoned carts"
  end
end
