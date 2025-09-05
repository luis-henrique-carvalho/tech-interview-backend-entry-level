# frozen_string_literal: true

module ApiHelper
  def response_body
    parsed = JSON.parse(response.body)
    parsed.is_a?(Array) ? parsed : parsed.with_indifferent_access
  end
end
