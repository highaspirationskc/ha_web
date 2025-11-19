# frozen_string_literal: true

require "test_helper"

class GraphQL::SchemaTest < ActiveSupport::TestCase
  test "schema is valid and has no errors" do
    # This validates the entire schema structure
    assert_nothing_raised do
      HaWebSchema.to_definition
    end
  end

  test "schema introspection query works" do
    # This is what GraphiQL does - if this fails, GraphiQL won't work
    query = <<~GQL
      query IntrospectionQuery {
        __schema {
          types {
            name
            kind
            description
          }
          queryType {
            name
          }
          mutationType {
            name
          }
        }
      }
    GQL

    result = HaWebSchema.execute(query)

    assert_nil result["errors"], "Schema introspection should not have errors: #{result['errors']&.map { |e| e['message'] }&.join(', ')}"
    assert_not_nil result.dig("data", "__schema", "types")
    assert_not_nil result.dig("data", "__schema", "queryType")
    assert_not_nil result.dig("data", "__schema", "mutationType")
  end

  test "all types are properly defined" do
    # Validate that all types can be accessed without errors
    assert_nothing_raised do
      HaWebSchema.types.each do |name, type|
        # This forces lazy loading of all types
        type.fields if type.respond_to?(:fields)
      end
    end
  end

  test "no duplicate type names exist" do
    type_names = HaWebSchema.types.keys
    duplicates = type_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    assert_empty duplicates, "Found duplicate type names: #{duplicates.join(', ')}"
  end

  test "all input types have at least one field" do
    HaWebSchema.types.values.each do |type|
      next unless type.is_a?(Class) && type < GraphQL::Schema::InputObject

      assert type.arguments.any?, "Input type #{type.graphql_name} must have at least one field"
    end
  end

  test "all mutations have unique graphql names" do
    mutation_names = Types::MutationType.fields.keys
    duplicates = mutation_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    assert_empty duplicates, "Found duplicate mutation names: #{duplicates.join(', ')}"
  end

  test "all queries have unique graphql names" do
    query_names = Types::QueryType.fields.keys
    duplicates = query_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys

    assert_empty duplicates, "Found duplicate query names: #{duplicates.join(', ')}"
  end
end
