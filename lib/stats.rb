module Stats
  def self.geometric_mean(values)
    return 0 unless values.is_a?(Array) and values.length > 0
    
    Math.exp ( values.map { |x| Math.log(x.to_f) }.reduce(&:+) / values.length )
  end
end