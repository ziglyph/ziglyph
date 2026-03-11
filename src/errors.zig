pub const Error = error{
    InvalidUtf8,
    OutOfMemory,
    Utf8CannotEncodeSurrogateHalf,
    CodepointTooLarge,
    NoSpaceLeft,
};
