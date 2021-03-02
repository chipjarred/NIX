# NIX

Not to be confused with the Nix package manager, `NIX` is a thin Swift wrapper around the POSIX system call API provided by Darwin and Linux to make working with that API easier and safer in Swift while preserving the basic feel of the POSIX API.

It provides improved type safety (for example flags are specific `OptionSet`s rather than `Int32` to prevent illegal values from being passed), attempts to remove the need for the caller to explicitly use `UnsafePointer`s, and separates normal return values from error indicators by returning either `NIX.Error?` or a `Result<T, NIX.Error>`.  I've specifically chosen not to use exceptions for error handling, because it deviates too much from the way the POSIX API is designed.

I'm making it available for others to use, but I've created it for my own use, and am improving and updating it when I have the need, so it's a work-in-progress (and is likely to be for a long time, given how large the POSIX API is).  If the functionality you're looking for is provided for by POSIX (or normally provided on Unix-like operating systems), please let me know, or even better contribute.

At the moment it mostly centers around socket functionality.
