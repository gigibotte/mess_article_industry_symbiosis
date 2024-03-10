module Exceptions
export WrongCoordinate, WrongCoordinateLevel, WrongInputLevel, WrongEssentialLevel, WrongConstraint, WrongCost, NoCarrier

struct WrongInputLevel <:Exception
    msg::String
end

struct WrongCoordinate <:Exception
    msg::String
end

struct WrongCoordinateLevel <:Exception
    msg::String
end

struct WrongEssentialLevel <:Exception
    msg::String
end

struct WrongConstraint <:Exception
    msg::String
end

struct WrongCost <:Exception
    msg::String
end

struct NoField <:Exception
    msg::String
end

struct NoCarrier <:Exception
    msg::String
end

end
