# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `commander` gem.
# Please instead update this file by running `bin/tapioca gem commander`.

# typed: true

module Blank
  class << self
    def included(base); end
  end
end

module Commander
  private

  def configure(*configuration_opts, &configuration_block); end

  class << self
    def configure(*configuration_opts, &configuration_block); end
  end
end

class Commander::Command
  def initialize(name); end

  def action(*args, &block); end
  def call(args = T.unsafe(nil)); end
  def description; end
  def description=(_arg0); end
  def example(description, command); end
  def examples; end
  def examples=(_arg0); end
  def global_options; end
  def inspect; end
  def name; end
  def name=(_arg0); end
  def option(*args, &block); end
  def option_proc(switches); end
  def options; end
  def options=(_arg0); end
  def parse_options_and_call_procs(*args); end
  def proxy_option_struct; end
  def proxy_options; end
  def proxy_options=(_arg0); end
  def run(*args); end
  def summary; end
  def summary=(_arg0); end
  def syntax; end
  def syntax=(_arg0); end
  def when_called(*args, &block); end
end

class Commander::Command::Options
  include ::Blank

  def initialize; end

  def __hash__; end
  def default(defaults = T.unsafe(nil)); end
  def inspect; end
  def method_missing(meth, *args); end
end

module Commander::Delegates
  def add_command(*args, &block); end
  def alias_command(*args, &block); end
  def always_trace!(*args, &block); end
  def command(*args, &block); end
  def default_command(*args, &block); end
  def defined_commands(*args, &block); end
  def global_option(*args, &block); end
  def never_trace!(*args, &block); end
  def program(*args, &block); end
  def run!(*args, &block); end
end

module Commander::HelpFormatter
  private

  def indent(amount, text); end

  class << self
    def indent(amount, text); end
  end
end

class Commander::HelpFormatter::Base
  def initialize(runner); end

  def render; end
  def render_command(command); end
end

class Commander::HelpFormatter::Context
  def initialize(target); end

  def decorate_binding(_bind); end
  def get_binding; end
end

class Commander::HelpFormatter::ProgramContext < ::Commander::HelpFormatter::Context
  def decorate_binding(bind); end
  def max_aliases_length(bind); end
  def max_command_length(bind); end
  def max_key_length(hash, default = T.unsafe(nil)); end
end

class Commander::HelpFormatter::Terminal < ::Commander::HelpFormatter::Base
  def render; end
  def render_command(command); end
  def template(name); end
end

class Commander::HelpFormatter::TerminalCompact < ::Commander::HelpFormatter::Terminal
  def template(name); end
end

module Commander::Methods
  include ::Commander::UI
  include ::Commander::UI::AskForClass
  include ::Commander::Delegates
end

module Commander::Platform
  class << self
    def jruby?; end
  end
end

class Commander::Runner
  def initialize(args = T.unsafe(nil)); end

  def active_command; end
  def add_command(command); end
  def alias?(name); end
  def alias_command(alias_name, name, *args); end
  def always_trace!; end
  def args_without_command_name; end
  def command(name, &block); end
  def command_exists?(name); end
  def command_name_from_args; end
  def commands; end
  def create_default_commands; end
  def default_command(name); end
  def expand_optionally_negative_switches(switches); end
  def global_option(*args, &block); end
  def global_option_proc(switches, &block); end
  def help_formatter; end
  def help_formatter_alias_defaults; end
  def help_formatter_aliases; end
  def never_trace!; end
  def options; end
  def parse_global_options; end
  def program(key, *args, &block); end
  def program_defaults; end
  def remove_global_options(options, args); end
  def require_program(*keys); end
  def require_valid_command(command = T.unsafe(nil)); end
  def run!; end
  def run_active_command; end
  def say(*args); end
  def valid_command_names_from(*args); end
  def version; end

  private

  def longest_valid_command_name_from(args); end

  class << self
    def instance; end
    def separate_switches_from_description(*args); end
    def switch_to_sym(switch); end
  end
end

class Commander::Runner::CommandError < ::StandardError; end
class Commander::Runner::InvalidCommandError < ::Commander::Runner::CommandError; end

module Commander::UI
  private

  def applescript(script); end
  def ask_editor(input = T.unsafe(nil), preferred_editor = T.unsafe(nil)); end
  def available_editor(preferred = T.unsafe(nil)); end
  def choose(message = T.unsafe(nil), *choices, &block); end
  def color(*args); end
  def converse(prompt, responses = T.unsafe(nil)); end
  def enable_paging; end
  def io(input = T.unsafe(nil), output = T.unsafe(nil), &block); end
  def log(action, *args); end
  def password(message = T.unsafe(nil), mask = T.unsafe(nil)); end
  def progress(arr, options = T.unsafe(nil)); end
  def replace_tokens(str, hash); end
  def say_error(*args); end
  def say_ok(*args); end
  def say_warning(*args); end
  def speak(message, voice = T.unsafe(nil), rate = T.unsafe(nil)); end

  class << self
    def applescript(script); end
    def ask_editor(input = T.unsafe(nil), preferred_editor = T.unsafe(nil)); end
    def available_editor(preferred = T.unsafe(nil)); end
    def choose(message = T.unsafe(nil), *choices, &block); end
    def color(*args); end
    def converse(prompt, responses = T.unsafe(nil)); end
    def enable_paging; end
    def io(input = T.unsafe(nil), output = T.unsafe(nil), &block); end
    def log(action, *args); end
    def password(message = T.unsafe(nil), mask = T.unsafe(nil)); end
    def progress(arr, options = T.unsafe(nil)); end
    def replace_tokens(str, hash); end
    def say_error(*args); end
    def say_ok(*args); end
    def say_warning(*args); end
    def speak(message, voice = T.unsafe(nil), rate = T.unsafe(nil)); end
  end
end

module Commander::UI::AskForClass
  def ask_for_array(prompt); end
  def ask_for_file(prompt); end
  def ask_for_float(prompt); end
  def ask_for_integer(prompt); end
  def ask_for_pathname(prompt); end
  def ask_for_regexp(prompt); end
  def ask_for_string(prompt); end
  def ask_for_symbol(prompt); end
  def method_missing(method_name, *arguments, &block); end

  private

  def respond_to_missing?(method_name, include_private = T.unsafe(nil)); end
end

Commander::UI::AskForClass::DEPRECATED_CONSTANTS = T.let(T.unsafe(nil), Array)

class Commander::UI::ProgressBar
  def initialize(total, options = T.unsafe(nil)); end

  def completed?; end
  def erase_line; end
  def finished?; end
  def generate_tokens; end
  def increment(tokens = T.unsafe(nil)); end
  def percent_complete; end
  def progress_bar; end
  def show; end
  def steps_remaining; end
  def time_elapsed; end
  def time_remaining; end
end

Commander::VERSION = T.let(T.unsafe(nil), String)

class Object < ::BasicObject
  include ::ActiveSupport::ForkTracker::CoreExt
  include ::ActiveSupport::ForkTracker::CoreExtPrivate
  include ::ActiveSupport::ToJsonWithActiveSupportEncoder
  include ::Kernel
  include ::JSON::Ext::Generator::GeneratorMethods::Object
  include ::PP::ObjectMixin
  include ::ActiveSupport::Tryable
  include ::ActiveSupport::Dependencies::Loadable

  def get_binding; end
end
