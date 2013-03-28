module FamilySearch
  class URLTemplate
    attr :template, :type, :accept, :allow, :title
    def initialize(client,template_hash)
      raise FamilySearch::Error::URLTemplateNotFound if template_hash.nil?
      @client = client
      @template = template_hash['template']
      @type = template_hash['type']
      @accept = template_hash['accept']
      @allow = template_hash['allow'].split(',').map{|v|v.downcase}
      @title = template_hash['title']
    end
    
    def get(template_values)
      raise FamilySearch::Error::MethodNotAllowed unless allow.include?('get')
      template_values = validate_values(template_values)
      url = make_url(template_values)
      params = make_params(template_values)
      @client.get url, params
    end
    
    private
    # "https://sandbox.familysearch.org/platform/tree/persons-with-relationships{?access_token,person}"
    def value_array
      template_value_array = []
      values = @template.scan(/\{([^}]*)\}/).flatten
      values.each do |value|
        value.gsub!('?','')
        template_value_array += value.split(',')
      end
      template_value_array
    end
    
    def validate_values(template_values)
      vals = value_array
      stringified_hash = {}
      template_values.each do |k,v|
        stringified_hash[k.to_s] = v
        raise FamilySearch::Error::TemplateValueNotFound unless vals.include?(k.to_s)
      end
      stringified_hash
    end
    
    # TODO: actually merge the values in
    def make_url(template_values)
      url = @template.gsub(/\{\?[^}]*\}/,'')
      template_values.each do |k,v|
        to_replace = "{#{k}}"
        url.gsub!(to_replace,v)
      end
      url
    end
    
    def make_params(template_values)
      to_remove = url_values
      to_remove.each do |v|
        template_values.delete(v)
      end
      template_values
    end
    
    def url_values
      @template.scan(/\{(\w*)\}/).flatten
    end
  end
end