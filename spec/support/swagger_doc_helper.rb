# frozen_string_literal: true

module SwaggerDocHelper
  def generate_response_examples
    after do |example|
      next unless response

      content = example.metadata[:response][:content] || {}
      example_name = example.metadata[:example_name] || 'Default'
      example_spec = {
        'application/json' => {
          examples: {
            example_name.to_sym => {
              value: JSON.parse(response.body, symbolize_names: true)
            }
          }
        }
      }
      example.metadata[:response][:content] = content.deep_merge(example_spec)
    end
  end

  def generate_request_examples
    after do |spec|
      next unless response

      spec.metadata[:operation][:request_examples] ||= []

      example = {
        value: JSON.parse(request.body.string, symbolize_names: true),
        name: "request_example#{rand(1..100)}",
        summary: spec.description.titleize
      }

      spec.metadata[:operation][:request_examples] << example
    end
  end
end
