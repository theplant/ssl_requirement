# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.before_filter(:ensure_proper_protocol)
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(*actions)
      write_inheritable_array(:ssl_required_actions, actions)
    end

    def ssl_allowed(*actions)
      write_inheritable_array(:ssl_allowed_actions, actions)
    end
  end

  protected
  # Returns true if the current action is supposed to run as SSL
  def ssl_required?
    ssl_required_actions = self.class.read_inheritable_attribute(:ssl_required_actions) || []
    return true if ssl_required_actions == [:all]
    ssl_required_actions.include?(action_name.to_sym)
  end

  def ssl_allowed?
    ssl_allowed_actions = self.class.read_inheritable_attribute(:ssl_allowed_actions) || []
    return true if ssl_allowed_actions == [:all]
    ssl_allowed_actions.include?(action_name.to_sym)
  end

  private
  def ensure_proper_protocol
    return if respond_to?(:skip_ssl_requirement) && skip_ssl_requirement
    return true unless request.get?
    return true if ssl_allowed?

    if ssl_required? && !request.ssl?
      redirect_to "https://" + request.host + request.fullpath
      flash.keep
      return false
    elsif request.ssl? && !ssl_required?
      redirect_to "http://" + request.host + request.fullpath
      flash.keep
      return false
    end
  end
end
