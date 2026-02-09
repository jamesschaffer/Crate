import Foundation

/// Static two-tier genre taxonomy with real Apple Music genre IDs.
///
/// Apple Music Genre IDs reference (as of 2024):
///   14 = Pop, 20 = Alternative, 21 = Rock, 18 = Hip-Hop/Rap,
///   7 = Electronic, 11 = Jazz, 6 = Country, 15 = R&B/Soul,
///   5 = Classical, 17 = Dance, 2 = Blues, 24 = Reggae,
///   22 = Singer/Songwriter, 10 = Latin, 29 = World
///
/// Sub-genre IDs come from Apple Music's catalog taxonomy.
enum Genres {

    static let all: [GenreCategory] = [
        rock,
        pop,
        hipHop,
        electronic,
        rAndB,
        jazz,
        country,
        classical,
        latin,
    ]

    // MARK: - Rock

    static let rock = GenreCategory(
        id: "rock",
        name: "Rock",
        appleMusicID: "21",
        subcategories: [
            SubCategory(id: "rock-alternative", name: "Alternative", appleMusicID: "20"),
            SubCategory(id: "rock-classic", name: "Classic Rock", appleMusicID: "1146"),
            SubCategory(id: "rock-indie", name: "Indie Rock", appleMusicID: "1151"),
            SubCategory(id: "rock-punk", name: "Punk", appleMusicID: "1154"),
            SubCategory(id: "rock-metal", name: "Metal", appleMusicID: "1153"),
            SubCategory(id: "rock-hard", name: "Hard Rock", appleMusicID: "1152"),
            SubCategory(id: "rock-prog", name: "Prog Rock", appleMusicID: "1166"),
            SubCategory(id: "rock-psychedelic", name: "Psychedelic", appleMusicID: "1167"),
        ]
    )

    // MARK: - Pop

    static let pop = GenreCategory(
        id: "pop",
        name: "Pop",
        appleMusicID: "14",
        subcategories: [
            SubCategory(id: "pop-adult-contemporary", name: "Adult Contemporary", appleMusicID: "1126"),
            SubCategory(id: "pop-indie", name: "Indie Pop", appleMusicID: "1136"),
            SubCategory(id: "pop-kpop", name: "K-Pop", appleMusicID: "1243"),
            SubCategory(id: "pop-jpop", name: "J-Pop", appleMusicID: "1064"),
            SubCategory(id: "pop-singer-songwriter", name: "Singer/Songwriter", appleMusicID: "22"),
            SubCategory(id: "pop-synth", name: "Synth Pop", appleMusicID: "1165"),
        ]
    )

    // MARK: - Hip-Hop/Rap

    static let hipHop = GenreCategory(
        id: "hiphop",
        name: "Hip-Hop/Rap",
        appleMusicID: "18",
        subcategories: [
            SubCategory(id: "hiphop-east-coast", name: "East Coast", appleMusicID: "1068"),
            SubCategory(id: "hiphop-west-coast", name: "West Coast", appleMusicID: "1069"),
            SubCategory(id: "hiphop-trap", name: "Trap", appleMusicID: "1207"),
            SubCategory(id: "hiphop-conscious", name: "Conscious", appleMusicID: "1066"),
            SubCategory(id: "hiphop-underground", name: "Underground", appleMusicID: "1072"),
            SubCategory(id: "hiphop-dirty-south", name: "Dirty South", appleMusicID: "1067"),
        ]
    )

    // MARK: - Electronic

    static let electronic = GenreCategory(
        id: "electronic",
        name: "Electronic",
        appleMusicID: "7",
        subcategories: [
            SubCategory(id: "electronic-house", name: "House", appleMusicID: "1048"),
            SubCategory(id: "electronic-techno", name: "Techno", appleMusicID: "1056"),
            SubCategory(id: "electronic-ambient", name: "Ambient", appleMusicID: "1046"),
            SubCategory(id: "electronic-drum-and-bass", name: "Drum & Bass", appleMusicID: "1047"),
            SubCategory(id: "electronic-dubstep", name: "Dubstep", appleMusicID: "1208"),
            SubCategory(id: "electronic-idm", name: "IDM", appleMusicID: "1049"),
            SubCategory(id: "electronic-trance", name: "Trance", appleMusicID: "1057"),
            SubCategory(id: "electronic-downtempo", name: "Downtempo", appleMusicID: "1058"),
        ]
    )

    // MARK: - R&B/Soul

    static let rAndB = GenreCategory(
        id: "rnb",
        name: "R&B/Soul",
        appleMusicID: "15",
        subcategories: [
            SubCategory(id: "rnb-contemporary", name: "Contemporary R&B", appleMusicID: "1141"),
            SubCategory(id: "rnb-classic-soul", name: "Classic Soul", appleMusicID: "1143"),
            SubCategory(id: "rnb-funk", name: "Funk", appleMusicID: "1144"),
            SubCategory(id: "rnb-neo-soul", name: "Neo-Soul", appleMusicID: "1145"),
        ]
    )

    // MARK: - Jazz

    static let jazz = GenreCategory(
        id: "jazz",
        name: "Jazz",
        appleMusicID: "11",
        subcategories: [
            SubCategory(id: "jazz-bebop", name: "Bebop", appleMusicID: "1106"),
            SubCategory(id: "jazz-contemporary", name: "Contemporary Jazz", appleMusicID: "1107"),
            SubCategory(id: "jazz-fusion", name: "Fusion", appleMusicID: "1108"),
            SubCategory(id: "jazz-latin", name: "Latin Jazz", appleMusicID: "1109"),
            SubCategory(id: "jazz-smooth", name: "Smooth Jazz", appleMusicID: "1110"),
        ]
    )

    // MARK: - Country

    static let country = GenreCategory(
        id: "country",
        name: "Country",
        appleMusicID: "6",
        subcategories: [
            SubCategory(id: "country-alternative", name: "Alternative Country", appleMusicID: "1034"),
            SubCategory(id: "country-americana", name: "Americana", appleMusicID: "1193"),
            SubCategory(id: "country-classic", name: "Classic Country", appleMusicID: "1035"),
            SubCategory(id: "country-contemporary", name: "Contemporary Country", appleMusicID: "1036"),
        ]
    )

    // MARK: - Classical

    static let classical = GenreCategory(
        id: "classical",
        name: "Classical",
        appleMusicID: "5",
        subcategories: [
            SubCategory(id: "classical-baroque", name: "Baroque", appleMusicID: "1021"),
            SubCategory(id: "classical-chamber", name: "Chamber Music", appleMusicID: "1022"),
            SubCategory(id: "classical-modern", name: "Modern", appleMusicID: "1025"),
            SubCategory(id: "classical-opera", name: "Opera", appleMusicID: "1026"),
            SubCategory(id: "classical-orchestral", name: "Orchestral", appleMusicID: "1027"),
        ]
    )

    // MARK: - Latin

    static let latin = GenreCategory(
        id: "latin",
        name: "Latin",
        appleMusicID: "12",
        subcategories: [
            SubCategory(id: "latin-reggaeton", name: "Reggaeton", appleMusicID: "1118"),
            SubCategory(id: "latin-salsa", name: "Salsa & Tropical", appleMusicID: "1119"),
            SubCategory(id: "latin-rock", name: "Latin Rock", appleMusicID: "1116"),
            SubCategory(id: "latin-pop", name: "Latin Pop", appleMusicID: "1115"),
        ]
    )
}
