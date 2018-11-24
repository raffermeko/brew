require "set"
require "cache_store"
require "searchable"

#
# `DescriptionCacheStore` provides methods to fetch and mutate linkage-specific data used
# by the `brew linkage` command.
#
class DescriptionCacheStore < CacheStore
  include Searchable

  # Inserts a formula description into the cache if it does not exist or
  # updates the formula description if it does exist.
  #
  # @param formula_name [String] the name of the formula to set
  # @param description  [String] the description from the formula to set
  # @return [nil]
  def update!(formula_name, description)
    database.set(formula_name, description)
  end

  # Delete the formula description from the `DescriptionCacheStore`.
  #
  # @param formula_name [String] the name of the formula to delete
  # @return [nil]
  def delete!(formula_name)
    database.delete(formula_name)
  end

  # If the database is empty `update!` it with all known formulae.
  # @return [nil]
  def populate_if_empty!
    return unless database.empty?

    Formula.each { |f| update!(f.full_name, f.desc) }
  end

  # Use an update report to update the `DescriptionCacheStore`.
  #
  # @param report [Report] an update report generated by cmd/update.rb
  # @return [nil]
  def update_from_report!(report)
    return populate_if_empty! if database.empty?
    return if report.empty?

    renamings   = report.select_formula(:R)
    alterations = report.select_formula(:A) +
                  report.select_formula(:M) +
                  renamings.map(&:last)

    update_from_formula_names!(alterations)
    delete_from_formula_names!(report.select_formula(:D) +
                               renamings.map(&:first))
  end

  # Use an array of formulae names to update the `DescriptionCacheStore`.
  #
  # @param formula_names [Array] the formulae to update
  # @return [nil]
  def update_from_formula_names!(formula_names)
    return populate_if_empty! if database.empty?

    formula_names.each do |name|
      begin
        update!(name, Formula[name].desc)
      rescue FormulaUnavailableError, *FormulaVersions::IGNORED_EXCEPTIONS
        delete!(name)
      end
    end
  end

  # Use an array of formulae names to delete them from the `DescriptionCacheStore`.
  #
  # @param formula_names [Array] the formulae to delete
  # @return [nil]
  def delete_from_formula_names!(formula_names)
    return if database.empty?

    formula_names.each(&method(:delete!))
  end

  private

  # Not implemented; access is through `Searchable`.
  def fetch
    super
  end

  # `select` from the underlying database.
  def select(&block)
    database.select(&block)
  end
end
