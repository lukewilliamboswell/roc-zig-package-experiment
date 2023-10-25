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
    antiAlias ? [X1, X4, X9, X16, X25],
    content : Str,
}

mainForHost : Str -> Str
mainForHost = \fromHost ->
    fromHost |> getToHost main 

getToHost : Str, Options -> Str
getToHost = \fromHost, { size ? Inherit, title ? "yeah", antiAlias ? X4, content }  ->
    when fromHost is 
        "TITLE" -> title
        "ALIAS" -> 
            when antiAlias is 
                X1 -> "X1"
                X4 -> "X4"
                X9 -> "X9"
                X16 -> "X16"
                X25 -> "X25"
        "SIZE" -> 
            when size is 
                Inherit -> "inherit"
                Set {width, height} -> "\(Num.toStr width)|\(Num.toStr height)"
        _ -> content
