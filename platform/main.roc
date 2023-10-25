platform "basic-graphics"
    requires {} { main : _ }
    exposes []
    packages {}
    imports [
        Dict,
    ]
    provides [mainForHost]

Options : {
    size ? [Inherit, Set {width : U32, height : U32}],
    title ? Str,
    content : Str,
}

mainForHost : Str -> Str
mainForHost = \fromHost ->
    fromHost |> getToHost main 

getToHost : Str, Options -> Str
getToHost = \fromHost, { size ? Inherit, title ? "yeah", content }  ->
    when fromHost is 
        "TITLE" -> title
        "SIZE" -> 
            when size is 
                Inherit -> "inherit"
                Set {width, height} -> "\(Num.toStr width)|\(Num.toStr height)"
        _ -> content
