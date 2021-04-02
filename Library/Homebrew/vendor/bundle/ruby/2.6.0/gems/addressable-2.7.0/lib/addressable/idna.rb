# frozen_string_literal: true

# encoding:utf-8
#--
# Copyright (C) Bob Aman
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#++


begin
  require "addressable/idna/native"
rescue LoadError
  # libidn or the idn gem was not available, fall back on a pure-Ruby
  # implementation...
  require "addressable/idna/pure"
end
