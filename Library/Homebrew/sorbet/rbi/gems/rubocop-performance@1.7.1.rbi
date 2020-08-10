# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rubocop-performance` gem.
# Please instead update this file by running `tapioca generate --exclude json`.

# typed: true

module RuboCop
end

module RuboCop::Cop
end

module RuboCop::Cop::Performance
end

class RuboCop::Cop::Performance::AncestorsInclude < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def ancestors_include_candidate?(node = T.unsafe(nil)); end
  def autocorrect(node); end
  def on_send(node); end
end

RuboCop::Cop::Performance::AncestorsInclude::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::BigDecimalWithNumericArgument < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def big_decimal_with_numeric_argument?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def specifies_precision?(node); end
end

RuboCop::Cop::Performance::BigDecimalWithNumericArgument::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::BindCall < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)
  extend(::RuboCop::Cop::TargetRubyVersion)

  def autocorrect(node); end
  def bind_with_call_method?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def build_call_args(call_args_node); end
  def correction_range(receiver, node); end
  def message(bind_arg, call_args); end
end

RuboCop::Cop::Performance::BindCall::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::Caller < ::RuboCop::Cop::Cop
  def caller_with_scope_method?(node = T.unsafe(nil)); end
  def on_send(node); end
  def slow_caller?(node = T.unsafe(nil)); end

  private

  def int_value(node); end
  def message(node); end
end

RuboCop::Cop::Performance::Caller::MSG_BRACE = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::Caller::MSG_FIRST = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::CaseWhenSplat < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::Alignment)
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(when_node); end
  def on_case(case_node); end

  private

  def indent_for(node); end
  def inline_fix_branch(corrector, when_node); end
  def needs_reorder?(when_node); end
  def new_branch_without_then(node, new_condition); end
  def new_condition_with_then(node, new_condition); end
  def non_splat?(condition); end
  def reorder_condition(corrector, when_node); end
  def reordering_correction(when_node); end
  def replacement(conditions); end
  def splat_offenses(when_conditions); end
  def when_branch_range(when_node); end
end

RuboCop::Cop::Performance::CaseWhenSplat::ARRAY_MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::CaseWhenSplat::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::Casecmp < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def downcase_downcase(node = T.unsafe(nil)); end
  def downcase_eq(node = T.unsafe(nil)); end
  def eq_downcase(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def build_good_method(arg, variable); end
  def correction(node, _receiver, method, arg, variable); end
  def take_method_apart(node); end
end

RuboCop::Cop::Performance::Casecmp::CASE_METHODS = T.let(T.unsafe(nil), Array)

RuboCop::Cop::Performance::Casecmp::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::ChainArrayAllocation < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def flat_map_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end
end

RuboCop::Cop::Performance::ChainArrayAllocation::ALWAYS_RETURNS_NEW_ARRAY = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::ChainArrayAllocation::HAS_MUTATION_ALTERNATIVE = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::ChainArrayAllocation::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::ChainArrayAllocation::RETURNS_NEW_ARRAY_WHEN_NO_BLOCK = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::ChainArrayAllocation::RETURN_NEW_ARRAY_WHEN_ARGS = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::CompareWithBlock < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def compare?(node = T.unsafe(nil)); end
  def on_block(node); end
  def replaceable_body?(node = T.unsafe(nil), param1, param2); end

  private

  def compare_range(send, node); end
  def message(send, method, var_a, var_b, args); end
  def slow_compare?(method, args_a, args_b); end
end

RuboCop::Cop::Performance::CompareWithBlock::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::Count < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def count_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def eligible_node?(node); end
  def source_starting_at(node); end
end

RuboCop::Cop::Performance::Count::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::DeletePrefix < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RegexpMetacharacter)
  extend(::RuboCop::Cop::TargetRubyVersion)

  def autocorrect(node); end
  def delete_prefix_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end
end

RuboCop::Cop::Performance::DeletePrefix::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::DeletePrefix::PREFERRED_METHODS = T.let(T.unsafe(nil), Hash)

class RuboCop::Cop::Performance::DeleteSuffix < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RegexpMetacharacter)
  extend(::RuboCop::Cop::TargetRubyVersion)

  def autocorrect(node); end
  def delete_suffix_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end
end

RuboCop::Cop::Performance::DeleteSuffix::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::DeleteSuffix::PREFERRED_METHODS = T.let(T.unsafe(nil), Hash)

class RuboCop::Cop::Performance::Detect < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def detect_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def accept_first_call?(receiver, body); end
  def lazy?(node); end
  def preferred_method; end
  def register_offense(node, receiver, second_method); end
end

RuboCop::Cop::Performance::Detect::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::Detect::REVERSE_MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::DoubleStartEndWith < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def check_with_active_support_aliases(node = T.unsafe(nil)); end
  def on_or(node); end
  def two_start_end_with_calls(node = T.unsafe(nil)); end

  private

  def add_offense_for_double_call(node, receiver, method, combined_args); end
  def check_for_active_support_aliases?; end
  def combine_args(first_call_args, second_call_args); end
  def process_source(node); end
end

RuboCop::Cop::Performance::DoubleStartEndWith::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::EndWith < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RegexpMetacharacter)

  def autocorrect(node); end
  def on_match_with_lvasgn(node); end
  def on_send(node); end
  def redundant_regex?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::EndWith::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::FixedSize < ::RuboCop::Cop::Cop
  def counter(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def allowed_argument?(arg); end
  def allowed_parent?(node); end
  def allowed_variable?(var); end
  def contains_double_splat?(node); end
  def contains_splat?(node); end
  def non_string_argument?(node); end
end

RuboCop::Cop::Performance::FixedSize::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::FlatMap < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def flat_map_candidate?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def offense_for_levels(node, map_node, first_method, flatten); end
  def offense_for_method(node, map_node, first_method, flatten); end
  def register_offense(node, map_node, first_method, flatten, message); end
end

RuboCop::Cop::Performance::FlatMap::FLATTEN_MULTIPLE_LEVELS = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::FlatMap::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::InefficientHashSearch < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def inefficient_include?(node = T.unsafe(nil)); end
  def on_send(node); end

  private

  def autocorrect_argument(node); end
  def autocorrect_hash_expression(node); end
  def autocorrect_method(node); end
  def current_method(node); end
  def message(node); end
  def use_long_method; end
end

class RuboCop::Cop::Performance::IoReadlines < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def on_send(node); end
  def readlines_on_class?(node = T.unsafe(nil)); end
  def readlines_on_instance?(node = T.unsafe(nil)); end

  private

  def build_bad_method(enumerable_call); end
  def build_call_args(call_args_node); end
  def build_good_method(enumerable_call); end
  def correction_range(enumerable_call, readlines_call); end
  def enumerable_method?(node); end
  def offense(node, enumerable_call, readlines_call); end
  def offense_range(enumerable_call, readlines_call); end
end

RuboCop::Cop::Performance::IoReadlines::ENUMERABLE_METHODS = T.let(T.unsafe(nil), Array)

RuboCop::Cop::Performance::IoReadlines::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::OpenStruct < ::RuboCop::Cop::Cop
  def on_send(node); end
  def open_struct(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::OpenStruct::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RangeInclude < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def on_send(node); end
  def range_include(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::RangeInclude::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantBlockCall < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def blockarg_assigned?(node0, param1); end
  def blockarg_calls(node0, param1); end
  def blockarg_def(node = T.unsafe(nil)); end
  def on_def(node); end

  private

  def args_include_block_pass?(blockcall); end
  def calls_to_report(argname, body); end
end

RuboCop::Cop::Performance::RedundantBlockCall::CLOSE_PAREN = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantBlockCall::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantBlockCall::OPEN_PAREN = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantBlockCall::SPACE = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantBlockCall::YIELD = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantMatch < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def match_call?(node = T.unsafe(nil)); end
  def on_send(node); end
  def only_truthiness_matters?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::RedundantMatch::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantMerge < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def modifier_flow_control?(node = T.unsafe(nil)); end
  def on_send(node); end
  def redundant_merge_candidate(node = T.unsafe(nil)); end

  private

  def correct_multiple_elements(node, parent, new_source); end
  def correct_single_element(node, new_source); end
  def each_redundant_merge(node); end
  def indent_width; end
  def kwsplat_used?(pairs); end
  def leading_spaces(node); end
  def max_key_value_pairs; end
  def message(node); end
  def non_redundant_merge?(node, receiver, pairs); end
  def non_redundant_pairs?(receiver, pairs); end
  def non_redundant_value_used?(receiver, node); end
  def rewrite_with_modifier(node, parent, new_source); end
  def to_assignments(receiver, pairs); end
end

RuboCop::Cop::Performance::RedundantMerge::AREF_ASGN = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantMerge::EachWithObjectInspector
  extend(::RuboCop::AST::NodePattern::Macros)

  def initialize(node, receiver); end

  def each_with_object_node(node = T.unsafe(nil)); end
  def value_used?; end

  private

  def eligible_receiver?; end
  def node; end
  def receiver; end
  def second_argument; end
  def unwind(receiver); end
end

RuboCop::Cop::Performance::RedundantMerge::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantMerge::WITH_MODIFIER_CORRECTION = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantSortBlock < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)
  include(::RuboCop::Cop::SortBlock)

  def autocorrect(node); end
  def on_block(node); end

  private

  def message(var_a, var_b); end
end

RuboCop::Cop::Performance::RedundantSortBlock::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::RedundantStringChars < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def on_send(node); end
  def redundant_chars_call?(node = T.unsafe(nil)); end

  private

  def build_bad_method(method, args); end
  def build_call_args(call_args_node); end
  def build_good_method(method, args); end
  def build_message(method, args); end
  def correction_range(receiver, node); end
  def offense_range(receiver, node); end
  def replaceable_method?(method_name); end
end

RuboCop::Cop::Performance::RedundantStringChars::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RedundantStringChars::REPLACEABLE_METHODS = T.let(T.unsafe(nil), Array)

class RuboCop::Cop::Performance::RegexpMatch < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def last_matches(node0); end
  def match_method?(node = T.unsafe(nil)); end
  def match_node?(node = T.unsafe(nil)); end
  def match_operator?(node = T.unsafe(nil)); end
  def match_threequals?(node = T.unsafe(nil)); end
  def match_with_int_arg_method?(node = T.unsafe(nil)); end
  def match_with_lvasgn?(node); end
  def on_case(node); end
  def on_if(node); end
  def search_match_nodes(node0); end

  private

  def check_condition(cond); end
  def correct_operator(corrector, recv, arg, oper = T.unsafe(nil)); end
  def correction_range(recv, arg); end
  def find_last_match(body, range, scope_root); end
  def last_match_used?(match_node); end
  def match_gvar?(sym); end
  def message(node); end
  def modifier_form?(match_node); end
  def next_match_pos(body, match_node_pos, scope_root); end
  def range_to_search_for_last_matches(match_node, body, scope_root); end
  def replace_with_match_predicate_method(corrector, recv, arg, op_range); end
  def scope_body(node); end
  def scope_root(node); end
  def swap_receiver_and_arg(corrector, recv, arg); end
end

RuboCop::Cop::Performance::RegexpMatch::MATCH_NODE_PATTERN = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RegexpMatch::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::RegexpMatch::TYPES_IMPLEMENTING_MATCH = T.let(T.unsafe(nil), Array)

class RuboCop::Cop::Performance::ReverseEach < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def on_send(node); end
  def reverse_each?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::ReverseEach::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::ReverseEach::UNDERSCORE = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::ReverseFirst < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def on_send(node); end
  def reverse_first_candidate?(node = T.unsafe(nil)); end

  private

  def build_bad_method(node); end
  def build_good_method(node); end
  def build_message(node); end
  def correction_range(receiver, node); end
end

RuboCop::Cop::Performance::ReverseFirst::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::Size < ::RuboCop::Cop::Cop
  def array?(node = T.unsafe(nil)); end
  def autocorrect(node); end
  def count?(node = T.unsafe(nil)); end
  def hash?(node = T.unsafe(nil)); end
  def on_send(node); end
end

RuboCop::Cop::Performance::Size::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::SortReverse < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)
  include(::RuboCop::Cop::SortBlock)

  def autocorrect(node); end
  def on_block(node); end

  private

  def message(var_a, var_b); end
end

RuboCop::Cop::Performance::SortReverse::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::Squeeze < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def on_send(node); end
  def squeeze_candidate?(node = T.unsafe(nil)); end

  private

  def repeating_literal?(regex_str); end
end

RuboCop::Cop::Performance::Squeeze::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::Squeeze::PREFERRED_METHODS = T.let(T.unsafe(nil), Hash)

class RuboCop::Cop::Performance::StartWith < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RegexpMetacharacter)

  def autocorrect(node); end
  def on_match_with_lvasgn(node); end
  def on_send(node); end
  def redundant_regex?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::StartWith::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::StringInclude < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def on_match_with_lvasgn(node); end
  def on_send(node); end
  def redundant_regex?(node = T.unsafe(nil)); end

  private

  def literal?(regex_str); end
end

RuboCop::Cop::Performance::StringInclude::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::StringReplacement < ::RuboCop::Cop::Cop
  include(::RuboCop::Cop::RangeHelp)

  def autocorrect(node); end
  def on_send(node); end
  def replace_method(node, first, second, first_param, replacement); end
  def string_replacement?(node = T.unsafe(nil)); end

  private

  def accept_first_param?(first_param); end
  def accept_second_param?(second_param); end
  def first_source(first_param); end
  def message(node, first_source, second_source); end
  def method_suffix(node); end
  def offense(node, first_param, second_param); end
  def range(node); end
  def remove_second_param(corrector, node, first_param); end
  def replacement_method(node, first_source, second_source); end
  def source_from_regex_constructor(node); end
  def source_from_regex_literal(node); end
end

RuboCop::Cop::Performance::StringReplacement::BANG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::StringReplacement::DELETE = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::StringReplacement::DETERMINISTIC_REGEX = T.let(T.unsafe(nil), Regexp)

RuboCop::Cop::Performance::StringReplacement::MSG = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::StringReplacement::TR = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::TimesMap < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def on_block(node); end
  def on_send(node); end
  def times_map_call(node = T.unsafe(nil)); end

  private

  def check(node); end
  def message(map_or_collect, count); end
end

RuboCop::Cop::Performance::TimesMap::MESSAGE = T.let(T.unsafe(nil), String)

RuboCop::Cop::Performance::TimesMap::MESSAGE_ONLY_IF = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::UnfreezeString < ::RuboCop::Cop::Cop
  def dup_string?(node = T.unsafe(nil)); end
  def on_send(node); end
  def string_new?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::UnfreezeString::MSG = T.let(T.unsafe(nil), String)

class RuboCop::Cop::Performance::UriDefaultParser < ::RuboCop::Cop::Cop
  def autocorrect(node); end
  def on_send(node); end
  def uri_parser_new?(node = T.unsafe(nil)); end
end

RuboCop::Cop::Performance::UriDefaultParser::MSG = T.let(T.unsafe(nil), String)

module RuboCop::Cop::RegexpMetacharacter

  private

  def drop_end_metacharacter(regexp_string); end
  def drop_start_metacharacter(regexp_string); end
  def literal_at_end?(regexp); end
  def literal_at_end_with_backslash_z?(regex_str); end
  def literal_at_end_with_dollar?(regex_str); end
  def literal_at_start?(regexp); end
  def literal_at_start_with_backslash_a?(regex_str); end
  def literal_at_start_with_caret?(regex_str); end
  def safe_multiline?; end
end

module RuboCop::Cop::SortBlock
  include(::RuboCop::Cop::RangeHelp)
  extend(::RuboCop::AST::NodePattern::Macros)

  def replaceable_body?(node = T.unsafe(nil), param1, param2); end
  def sort_with_block?(node = T.unsafe(nil)); end

  private

  def sort_range(send, node); end
end

RuboCop::NodePattern = RuboCop::AST::NodePattern

module RuboCop::Performance
end

RuboCop::Performance::CONFIG = T.let(T.unsafe(nil), Hash)

module RuboCop::Performance::Inject
  class << self
    def defaults!; end
  end
end

module RuboCop::Performance::Version
end

RuboCop::Performance::Version::STRING = T.let(T.unsafe(nil), String)

RuboCop::ProcessedSource = RuboCop::AST::ProcessedSource

RuboCop::Token = RuboCop::AST::Token
