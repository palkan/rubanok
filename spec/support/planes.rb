# frozen_string_literal: true

class RejectPlane < Rubanok::Plane
  map :type do |type|
    data.reject { |item| item[:type] == type }
  end
end

class PostPlane < Rubanok::Plane
  map :type do |type|
    data.select { |item| item[:type] == type }
  end
end
