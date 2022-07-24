# frozen_string_literal: true
# typed: true

module T::Private::Methods::SignatureValidation
  Methods = T::Private::Methods
  Modes = Methods::Modes

  def self.validate(signature)
    if signature.method_name == :initialize && signature.method.owner.is_a?(Class)
      # Constructors are special. They look like overrides in terms of a super_method existing,
      # but in practice, you never call them polymorphically. Conceptually, they're standard
      # methods (this is consistent with how they're treated in other languages, e.g. Java)
      if signature.mode != Modes.standard
        raise "`initialize` should not use `.abstract` or `.implementation` or any other inheritance modifiers."
      end
      return
    end

    super_method = signature.method.super_method

    if super_method && super_method.owner != signature.method.owner
      Methods.maybe_run_sig_block_for_method(super_method)
      super_signature = Methods.signature_for_method(super_method)

      # If the super_method has any kwargs we can't build a
      # Signature for it, so we'll just skip validation in that case.
      if !super_signature && !super_method.parameters.select {|kind, _| kind == :rest || kind == :kwrest}.empty?
        nil
      else
        # super_signature can be nil when we're overriding a method (perhaps a builtin) that didn't use
        # one of the method signature helpers. Use an untyped signature so we can still validate
        # everything but types.
        #
        # We treat these signatures as overridable, that way people can use `.override` with
        # overrides of builtins. In the future we could try to distinguish when the method is a
        # builtin and treat non-builtins as non-overridable (so you'd be forced to declare them with
        # `.overridable`).
        #
        super_signature ||= Methods::Signature.new_untyped(method: super_method)

        validate_override_mode(signature, super_signature)
        validate_override_shape(signature, super_signature)
        validate_override_types(signature, super_signature)
      end
    else
      validate_non_override_mode(signature)
    end
  end

  private_class_method def self.pretty_mode(signature)
    if signature.mode == Modes.overridable_override
      '.overridable.override'
    else
      ".#{signature.mode}"
    end
  end

  def self.validate_override_mode(signature, super_signature)
    case signature.mode
    when *Modes::OVERRIDE_MODES
      # Peaceful
    when *Modes::NON_OVERRIDE_MODES
      if super_signature.mode == Modes.standard
        # Peaceful
      elsif super_signature.mode == Modes.abstract
        raise "You must use `.override` when overriding the abstract method `#{signature.method_name}`.\n" \
              "  Abstract definition: #{method_loc_str(super_signature.method)}\n" \
              "  Implementation definition: #{method_loc_str(signature.method)}\n"
      elsif super_signature.mode != Modes.untyped
        raise "You must use `.override` when overriding the existing method `#{signature.method_name}`.\n" \
              "  Parent definition: #{method_loc_str(super_signature.method)}\n" \
              "  Child definition:  #{method_loc_str(signature.method)}\n"
      end
    else
      raise "Unexpected mode: #{signature.mode}. Please report this bug at https://github.com/sorbet/sorbet/issues"
    end
  end

  def self.validate_non_override_mode(signature)
    case signature.mode
    when Modes.override
      if signature.method_name == :each && signature.method.owner < Enumerable
        # Enumerable#each is the only method in Sorbet's RBI payload that defines an abstract method.
        # Enumerable#each does not actually exist at runtime, but it is required to be implemented by
        # any class which includes Enumerable. We want to declare Enumerable#each as abstract so that
        # people can call it anything which implements the Enumerable interface, and so that it's a
        # static error to forget to implement it.
        #
        # This is a one-off hack, and we should think carefully before adding more methods here.
        nil
      else
        raise "You marked `#{signature.method_name}` as #{pretty_mode(signature)}, but that method doesn't already exist in this class/module to be overriden.\n" \
          "  Either check for typos and for missing includes or super classes to make the parent method shows up\n" \
          "  ... or remove #{pretty_mode(signature)} here: #{method_loc_str(signature.method)}\n"
      end
    when Modes.standard, *Modes::NON_OVERRIDE_MODES
      # Peaceful
      nil
    else
      raise "Unexpected mode: #{signature.mode}. Please report this bug at https://github.com/sorbet/sorbet/issues"
    end

    # Given a singleton class, we can check if it belongs to a
    # module by looking at its superclass; given `module M`,
    # `M.singleton_class.superclass == Module`, which is not true
    # for any class.
    owner = signature.method.owner
    if (signature.mode == Modes.abstract || Modes::OVERRIDABLE_MODES.include?(signature.mode)) &&
        owner.singleton_class? && owner.superclass == Module
      raise "Defining an overridable class method (via #{pretty_mode(signature)}) " \
            "on a module is not allowed. Class methods on " \
            "modules do not get inherited and thus cannot be overridden."
    end
  end

  def self.validate_override_shape(signature, super_signature)
    return if signature.override_allow_incompatible
    return if super_signature.mode == Modes.untyped

    method_name = signature.method_name
    mode_verb = super_signature.mode == Modes.abstract ? 'implements' : 'overrides'

    if !signature.has_rest && signature.arg_count < super_signature.arg_count
      raise "Your definition of `#{method_name}` must accept at least #{super_signature.arg_count} " \
            "positional arguments to be compatible with the method it #{mode_verb}: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end

    if !signature.has_rest && super_signature.has_rest
      raise "Your definition of `#{method_name}` must have `*#{super_signature.rest_name}` " \
            "to be compatible with the method it #{mode_verb}: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end

    if signature.req_arg_count > super_signature.req_arg_count
      raise "Your definition of `#{method_name}` must have no more than #{super_signature.req_arg_count} " \
            "required argument(s) to be compatible with the method it #{mode_verb}: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end

    if !signature.has_keyrest
      # O(nm), but n and m are tiny here
      missing_kwargs = super_signature.kwarg_names - signature.kwarg_names
      if !missing_kwargs.empty?
        raise "Your definition of `#{method_name}` is missing these keyword arg(s): #{missing_kwargs} " \
              "which are defined in the method it #{mode_verb}: " \
              "#{base_override_loc_str(signature, super_signature)}"
      end
    end

    if !signature.has_keyrest && super_signature.has_keyrest
      raise "Your definition of `#{method_name}` must have `**#{super_signature.keyrest_name}` " \
            "to be compatible with the method it #{mode_verb}: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end

    # O(nm), but n and m are tiny here
    extra_req_kwargs = signature.req_kwarg_names - super_signature.req_kwarg_names
    if !extra_req_kwargs.empty?
      raise "Your definition of `#{method_name}` has extra required keyword arg(s) " \
            "#{extra_req_kwargs} relative to the method it #{mode_verb}, making it incompatible: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end

    if super_signature.block_name && !signature.block_name
      raise "Your definition of `#{method_name}` must accept a block parameter to be compatible " \
            "with the method it #{mode_verb}: " \
            "#{base_override_loc_str(signature, super_signature)}"
    end
  end

  def self.validate_override_types(signature, super_signature)
    return if signature.override_allow_incompatible
    return if super_signature.mode == Modes.untyped
    return unless [signature, super_signature].all? do |sig|
      sig.check_level == :always || sig.check_level == :compiled || (sig.check_level == :tests && T::Private::RuntimeLevels.check_tests?)
    end
    mode_noun = super_signature.mode == Modes.abstract ? 'implementation' : 'override'

    # arg types must be contravariant
    super_signature.arg_types.zip(signature.arg_types).each_with_index do |((_super_name, super_type), (name, type)), index|
      if !super_type.subtype_of?(type)
        raise "Incompatible type for arg ##{index + 1} (`#{name}`) in signature for #{mode_noun} of method " \
              "`#{signature.method_name}`:\n" \
              "* Base: `#{super_type}` (in #{method_loc_str(super_signature.method)})\n" \
              "* #{mode_noun.capitalize}: `#{type}` (in #{method_loc_str(signature.method)})\n" \
              "(The types must be contravariant.)"
      end
    end

    # kwarg types must be contravariant
    super_signature.kwarg_types.each do |name, super_type|
      type = signature.kwarg_types[name]
      if !super_type.subtype_of?(type)
        raise "Incompatible type for arg `#{name}` in signature for #{mode_noun} of method `#{signature.method_name}`:\n" \
              "* Base: `#{super_type}` (in #{method_loc_str(super_signature.method)})\n" \
              "* #{mode_noun.capitalize}: `#{type}` (in #{method_loc_str(signature.method)})\n" \
              "(The types must be contravariant.)"
      end
    end

    # return types must be covariant
    if !signature.return_type.subtype_of?(super_signature.return_type)
      raise "Incompatible return type in signature for #{mode_noun} of method `#{signature.method_name}`:\n" \
            "* Base: `#{super_signature.return_type}` (in #{method_loc_str(super_signature.method)})\n" \
            "* #{mode_noun.capitalize}: `#{signature.return_type}` (in #{method_loc_str(signature.method)})\n" \
            "(The types must be covariant.)"
    end
  end

  private_class_method def self.base_override_loc_str(signature, super_signature)
    mode_noun = super_signature.mode == Modes.abstract ? 'Implementation' : 'Override'
    "\n * Base definition: in #{method_loc_str(super_signature.method)}" \
    "\n * #{mode_noun}: in #{method_loc_str(signature.method)}"
  end

  private_class_method def self.method_loc_str(method)
    loc = if method.source_location
      method.source_location.join(':')
    else
      "<unknown location>"
    end
    "#{method.owner} at #{loc}"
  end
end
