# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Activate schema strict mode
  config.openapi_strict_schema_validation = true

  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, CL
  paths = Dir.glob('spec/components/schemas/**/*.json')

  path_contents = paths.reduce({}) do |previous_hash, path|
    content = JSON.parse(File.read(path))
    clean_path = path.gsub('spec/components/schemas/', '').gsub('.json', '').split('/')
    full_schema = clean_path.reverse.inject(content) { |assigned_value, key| { key => assigned_value } }

    previous_hash.deep_merge(full_schema)
  end

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer
          }
        },
        schemas: path_contents
      },
      servers: [
        {
          url: 'http://localhost:3000'
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
