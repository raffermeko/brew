# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `hana` gem.
# Please instead update this file by running `bin/tapioca gem hana`.

module Hana; end

class Hana::Patch
  def initialize(is); end

  def apply(doc); end

  private

  def add(ins, doc); end
  def add_op(dest, key, obj); end
  def check_index(obj, key); end
  def copy(ins, doc); end
  def get_path(ins); end
  def move(ins, doc); end
  def remove(ins, doc); end
  def replace(ins, doc); end
  def rm_op(obj, key); end
  def test(ins, doc); end
end

class Hana::Patch::Exception < ::StandardError; end
Hana::Patch::FROM = T.let(T.unsafe(nil), String)

class Hana::Patch::FailedTestException < ::Hana::Patch::Exception
  def initialize(path, value); end

  def path; end
  def path=(_arg0); end
  def value; end
  def value=(_arg0); end
end

class Hana::Patch::IndexError < ::Hana::Patch::Exception; end
class Hana::Patch::InvalidObjectOperationException < ::Hana::Patch::Exception; end
class Hana::Patch::InvalidPath < ::Hana::Patch::Exception; end
class Hana::Patch::MissingTargetException < ::Hana::Patch::Exception; end
class Hana::Patch::ObjectOperationOnArrayException < ::Hana::Patch::Exception; end
class Hana::Patch::OutOfBoundsException < ::Hana::Patch::Exception; end
Hana::Patch::VALID = T.let(T.unsafe(nil), Hash)
Hana::Patch::VALUE = T.let(T.unsafe(nil), String)

class Hana::Pointer
  include ::Enumerable

  def initialize(path); end

  def each(&block); end
  def eval(object); end

  class << self
    def eval(list, object); end
    def parse(path); end
  end
end

Hana::Pointer::ESC = T.let(T.unsafe(nil), Hash)
class Hana::Pointer::Exception < ::StandardError; end
class Hana::Pointer::FormatError < ::Hana::Pointer::Exception; end
Hana::VERSION = T.let(T.unsafe(nil), String)
