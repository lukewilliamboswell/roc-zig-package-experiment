app "example"
    packages {
        # pf: "https://github.com/lukewilliamboswell/roc-things/releases/download/test-graphics/_P85vkqYR8LdQD5FowyGURrNZ1wvrl1KopIvB4sGgGA.tar.br",
        pf: "../platform/main.roc",
        # tvg: "https://github.com/lukewilliamboswell/roc-tinvyvg/releases/download/0.2/ZyZBFnr3PEd5fWq70Z6w2ASK7bSxarh8Wj2Xq7o7IUE.tar.br",
    }
    imports [
        Dict,
    ]
    provides [main] to pf

main = 
    {
        size: Set {width : 500, height : 500},
        title: "ROC YEAH",
        content: rocBirdLogo,
    }
    
# shieldDemo = 
# #     Str.toUtf8 """(tvg 1        (24 24 1/4 u8888 reduced)        (            (0.161 0.678 1.000)            (1.000 0.945 0.910)        )        (            (            fill_path            (flat 0)            (                (12 1)                (                (line - 3 5)                (vert - 11)                (bezier - (3 16.5) (6.75 21.75) (12 23))                (bezier - (17.25 21.75) (21 16.5) (21 11))                (vert - 5)                )                (17.25 17)                (                (bezier - (16 18.75) (14 20.25) (12 21))                (bezier - (10 20.25) (8 18.75) (6.75 17))                (bezier - (6.5 16.5) (6.25 16) (6 15.5))                (bezier - (6 13.75) (8.75 12.5) (12 12.5))                (bezier - (15.25 12.5) (18 13.75) (18 15.5))                (bezier - (17.75 16) (17.5 16.5) (17.25 17))                )                (12 5)                (                (bezier - (13.5 5) (15 6.25) (15 8))                (bezier - (15 9.5) (13.75 11) (12 11))                (bezier - (10.5 11) (9 9.75) (9 8))                (bezier - (9 6.5) (10.25 5) (12 5))                )            )            )        )        )"""       
        
rocBirdLogo = 
    "(tvg 1 (100 100 1/1 u8888 default)((1.0 1.0 1.0 1.0)(0.48 0.21 0.96 1.0))((fill_path (flat 0) ((0.0 0.0) ((line - 100.0 0.0)(line - 100.0 100.0)(line - 0.0 100.0)(close -))))(fill_path (flat 1) ((24.75 23.5) ((line - 48.633 26.711)(line - 61.994 42.51)(line - 70.716 40.132)(line - 75.25 45.5)(line - 69.75 45.5)(line - 68.782 49.869)(line - 51.217 62.842)(line - 52.203 68.713)(line - 42.405 76.5)(line - 48.425 46.209)(close -))))))"
