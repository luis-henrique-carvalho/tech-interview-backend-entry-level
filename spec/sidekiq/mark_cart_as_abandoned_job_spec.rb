require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    let!(:active_cart_recent) { create(:cart, last_interaction_at: 1.hour.ago) }
    let!(:active_cart_old) { create(:cart, last_interaction_at: 4.hours.ago, abandoned_at: nil) }
    let!(:abandoned_cart_recent) { create(:cart, abandoned_at: 1.day.ago, last_interaction_at: 5.hours.ago) }
    let!(:abandoned_cart_old) { create(:cart, abandoned_at: 8.days.ago, last_interaction_at: 9.days.ago) }

    it 'marks carts as abandoned when inactive for more than 3 hours' do
      expect { described_class.new.perform }
        .to change { active_cart_old.reload.abandoned_at }
        .from(nil)
        .to be_present
    end

    it 'does not mark recently active carts as abandoned' do
      expect { described_class.new.perform }
        .not_to change { active_cart_recent.reload.abandoned_at }
    end

    it 'does not mark already abandoned carts' do
      expect { described_class.new.perform }
        .not_to change { abandoned_cart_recent.reload.abandoned_at }
    end

    it 'removes carts abandoned for more than 7 days' do
      expect { described_class.new.perform }
        .to change { Cart.exists?(abandoned_cart_old.id) }
        .from(true)
        .to(false)
    end

    it 'does not remove recently abandoned carts' do
      expect { described_class.new.perform }
        .not_to change { Cart.exists?(abandoned_cart_recent.id) }
    end

    it 'logs the number of carts marked as abandoned' do
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with(/Marked \d+ carts as abandoned/)
    end

    it 'logs the number of old abandoned carts removed' do
      allow(Rails.logger).to receive(:info)

      described_class.new.perform

      expect(Rails.logger).to have_received(:info).with(/Removed \d+ old abandoned carts/)
    end
  end
end
