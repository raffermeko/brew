# typed: strict
# frozen_string_literal: true

require "test_runner_formula"

class GitHubRunnerMatrix
  extend T::Sig

  # FIXME: sig { returns(T::Array[RunnerSpec]) }
  sig { returns(T::Array[RunnerHashValue]) }
  attr_reader :active_runners

  # FIXME: Enable cop again when https://github.com/sorbet/sorbet/issues/3532 is fixed.
  # rubocop:disable Style/MutableConstant
  RunnerSpec = T.type_alias do
    T.any(
      T::Hash[Symbol, T.any(String, T::Hash[Symbol, String], Integer, T::Boolean)], # Linux
      T::Hash[Symbol, T.any(String, T::Boolean)], # macOS
    )
  end
  private_constant :RunnerSpec
  RunnerHashValue = T.type_alias { T.any(Symbol, RunnerSpec, T.nilable(OS::Mac::Version)) }
  private_constant :RunnerHashValue
  # rubocop:enable Style/MutableConstant

  sig {
    params(
      available_runners: T::Array[T::Hash[Symbol, RunnerHashValue]],
      testing_formulae:  T::Array[TestRunnerFormula],
      deleted_formulae:  T.nilable(T::Array[String]),
      dependent_matrix:  T::Boolean,
    ).void
  }
  def initialize(available_runners, testing_formulae, deleted_formulae, dependent_matrix:)
    @available_runners = T.let(available_runners, T::Array[T::Hash[Symbol, RunnerHashValue]])
    @testing_formulae = T.let(testing_formulae, T::Array[TestRunnerFormula])
    @deleted_formulae = T.let(deleted_formulae, T.nilable(T::Array[String]))
    @dependent_matrix = T.let(dependent_matrix, T::Boolean)
    # FIXME: Should have type `RunnerSpec`, but Sorbet can't infer that that's correct.
    @active_runners = T.let([], T::Array[RunnerHashValue])

    generate_runners!

    freeze
  end

  sig { void }
  def generate_runners!
    @available_runners.each do |runner|
      @active_runners << runner.fetch(:runner_spec) if add_runner?(runner)
    end
  end

  sig { params(runner: T::Hash[Symbol, RunnerHashValue]).returns([Symbol, Symbol, T.nilable(OS::Mac::Version)]) }
  def unpack_runner(runner)
    platform = runner.fetch(:platform)
    raise "Unexpected platform: #{platform}" if !platform.is_a?(Symbol) || [:macos, :linux].exclude?(platform)

    arch = runner.fetch(:arch)
    raise "Unexpected arch: #{arch}" if !arch.is_a?(Symbol) || [:arm64, :x86_64].exclude?(arch)

    macos_version = runner.fetch(:macos_version)
    if !macos_version.nil? && !macos_version.is_a?(OS::Mac::Version)
      raise "Unexpected macos_version: #{macos_version}"
    end

    [platform, arch, macos_version]
  end

  sig { params(runner: T::Hash[Symbol, RunnerHashValue]).returns(T::Boolean) }
  def add_runner?(runner)
    if @dependent_matrix
      formulae_have_untested_dependents?(runner)
    else
      return true if @deleted_formulae.present?

      compatible_formulae = @testing_formulae.dup

      platform, arch, macos_version = unpack_runner(runner)

      compatible_formulae.select! { |formula| formula.send(:"#{platform}_compatible?") }
      compatible_formulae.select! { |formula| formula.send(:"#{arch}_compatible?") }
      compatible_formulae.select! { |formula| formula.compatible_with?(macos_version) } if macos_version

      compatible_formulae.present?
    end
  end

  sig { params(runner: T::Hash[Symbol, RunnerHashValue]).returns(T::Boolean) }
  def formulae_have_untested_dependents?(runner)
    platform, arch, macos_version = unpack_runner(runner)

    @testing_formulae.any? do |formula|
      # If the formula has a platform/arch/macOS version requirement, then its
      # dependents don't need to be tested if these requirements are not satisfied.
      next false unless formula.send(:"#{platform}_compatible?")
      next false unless formula.send(:"#{arch}_compatible?")
      next false if macos_version.present? && !formula.compatible_with?(macos_version)

      compatible_dependents = formula.dependents(platform: platform, arch: arch, macos_version: macos_version&.to_sym)
                                     .dup

      compatible_dependents.select! { |dependent_f| dependent_f.send(:"#{platform}_compatible?") }
      compatible_dependents.select! { |dependent_f| dependent_f.send(:"#{arch}_compatible?") }
      compatible_dependents.select! { |dependent_f| dependent_f.compatible_with?(macos_version) } if macos_version

      (compatible_dependents - @testing_formulae).present?
    end
  end
end
