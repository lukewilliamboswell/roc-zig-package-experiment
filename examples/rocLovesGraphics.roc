app "example"
    packages {
        pf: "../platform/main.roc",
        tvg: "https://github.com/lukewilliamboswell/roc-tinvyvg/releases/download/0.2/ZyZBFnr3PEd5fWq70Z6w2ASK7bSxarh8Wj2Xq7o7IUE.tar.br",
    }
    imports [
        Dict,
        tvg.Graphic,
        tvg.Color,
        tvg.Style,
        tvg.Command,
        tvg.PathNode,
    ]
    provides [main] to pf

main = { title: "bird", content: tvgText }

tvgText =
    graphic =
        g0 = Graphic.graphic {}
        g1, white <- g0 |> Graphic.applyColor (Color.fromBasic White)
        g2, purple <- g1 |> Graphic.applyColor (Color.rocPurple)

        # Draws the white square background
        whiteSquare = Command.fillPath (Style.flat white) { x: 0, y: 0 } [
            PathNode.line { x: 100, y: 0 },
            PathNode.line { x: 100, y: 100 },
            PathNode.line { x: 0, y: 100 },
            PathNode.close {},
        ]

        # Draws the roc-lang bird logo
        rocBird = Command.fillPath (Style.flat purple) { x: 24.75, y: 23.5 } [
            PathNode.line { x: 48.633, y: 26.711 },
            PathNode.line { x: 61.994, y: 42.51 },
            PathNode.line { x: 70.716, y: 40.132 },
            PathNode.line { x: 75.25, y: 45.5 },
            PathNode.line { x: 69.75, y: 45.5 },
            PathNode.line { x: 68.782, y: 49.869 },
            PathNode.line { x: 51.217, y: 62.842 },
            PathNode.line { x: 52.203, y: 68.713 },
            PathNode.line { x: 42.405, y: 76.5 },
            PathNode.line { x: 48.425, y: 46.209 },
            PathNode.close {},
        ]

        g2
        |> Graphic.addCommand whiteSquare
        |> Graphic.addCommand rocBird

    Graphic.toText graphic

