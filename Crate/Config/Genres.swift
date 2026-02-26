import Foundation

/// Static two-tier genre taxonomy with real Apple Music genre IDs.
///
/// Apple Music Genre IDs reference (parent genres):
///   21 = Rock, 14 = Pop, 18 = Hip-Hop/Rap, 7 = Electronic,
///   15 = R&B/Soul, 10 = Singer/Songwriter, 11 = Jazz, 2 = Blues,
///   6 = Country, 5 = Classical, 12 = Latin, 16 = Soundtrack
///
/// Sub-genre IDs verified against Apple's public genre API:
///   https://itunes.apple.com/WebObjects/MZStoreServices.woa/ws/genres?id={parentID}
enum Genres {

    static let all: [GenreCategory] = [
        rock,
        pop,
        hipHop,
        electronic,
        rAndB,
        singerSongwriter,
        jazz,
        blues,
        country,
        classical,
        latin,
        soundtrack,
    ]

    // MARK: - Rock

    static let rock = GenreCategory(
        id: "rock",
        name: "Rock",
        appleMusicID: "21",
        subcategories: [
            SubCategory(id: "rock-adult-alternative", name: "Adult Alternative", appleMusicID: "1144"),
            SubCategory(id: "rock-roots", name: "Roots Rock", appleMusicID: "1159"),
            SubCategory(id: "rock-blues-rock", name: "Blues-Rock", appleMusicID: "1147"),
            SubCategory(id: "rock-rock-and-roll", name: "Rock & Roll", appleMusicID: "1157"),
            SubCategory(id: "rock-metal", name: "Metal", appleMusicID: "1153"),
            SubCategory(id: "rock-hard", name: "Hard Rock", appleMusicID: "1152"),
            SubCategory(id: "rock-prog", name: "Prog-Rock/Art Rock", appleMusicID: "1155"),
            SubCategory(id: "rock-psychedelic", name: "Psychedelic", appleMusicID: "1156"),
        ]
    )

    // MARK: - Pop

    static let pop = GenreCategory(
        id: "pop",
        name: "Pop",
        appleMusicID: "14",
        subcategories: [
            SubCategory(id: "pop-adult-contemporary", name: "Adult Contemporary", appleMusicID: "1131"),
            SubCategory(id: "pop-britpop", name: "Britpop", appleMusicID: "1132"),
            SubCategory(id: "pop-kpop", name: "K-Pop", appleMusicID: "51"),
            SubCategory(id: "pop-pop-rock", name: "Pop/Rock", appleMusicID: "1133"),
            SubCategory(id: "pop-soft-rock", name: "Soft Rock", appleMusicID: "1134"),
        ]
    )

    // MARK: - Hip-Hop/Rap

    static let hipHop = GenreCategory(
        id: "hiphop",
        name: "Hip-Hop/Rap",
        appleMusicID: "18",
        subcategories: [
            SubCategory(id: "hiphop-east-coast", name: "East Coast Rap", appleMusicID: "1070"),
            SubCategory(id: "hiphop-west-coast", name: "West Coast Rap", appleMusicID: "1078"),
            SubCategory(id: "hiphop-gangsta", name: "Gangsta Rap", appleMusicID: "1071"),
            SubCategory(id: "hiphop-alternative", name: "Alternative Rap", appleMusicID: "1068"),
            SubCategory(id: "hiphop-underground", name: "Underground Rap", appleMusicID: "1077"),
            SubCategory(id: "hiphop-dirty-south", name: "Dirty South", appleMusicID: "1069"),
        ]
    )

    // MARK: - Electronic

    static let electronic = GenreCategory(
        id: "electronic",
        name: "Electronic",
        appleMusicID: "7",
        subcategories: [
            SubCategory(id: "electronic-ambient", name: "Ambient", appleMusicID: "1056"),
            SubCategory(id: "electronic-bass", name: "Bass", appleMusicID: "100015"),
            SubCategory(id: "electronic-downtempo", name: "Downtempo", appleMusicID: "1057"),
            SubCategory(id: "electronic-dubstep", name: "Dubstep", appleMusicID: "100014"),
            SubCategory(id: "electronic-electronica", name: "Electronica", appleMusicID: "1058"),
            SubCategory(id: "electronic-idm", name: "IDM/Experimental", appleMusicID: "1060"),
            SubCategory(id: "electronic-industrial", name: "Industrial", appleMusicID: "1061"),
        ]
    )

    // MARK: - R&B/Soul

    static let rAndB = GenreCategory(
        id: "rnb",
        name: "R&B/Soul",
        appleMusicID: "15",
        subcategories: [
            SubCategory(id: "rnb-contemporary", name: "Contemporary R&B", appleMusicID: "1136"),
            SubCategory(id: "rnb-soul", name: "Soul", appleMusicID: "1143"),
            SubCategory(id: "rnb-funk", name: "Funk", appleMusicID: "1139"),
            SubCategory(id: "rnb-neo-soul", name: "Neo-Soul", appleMusicID: "1141"),
        ]
    )

    // MARK: - Jazz

    static let jazz = GenreCategory(
        id: "jazz",
        name: "Jazz",
        appleMusicID: "11",
        subcategories: [
            SubCategory(id: "jazz-bop", name: "Bop", appleMusicID: "1053"),
            SubCategory(id: "jazz-contemporary", name: "Contemporary Jazz", appleMusicID: "1107"),
            SubCategory(id: "jazz-fusion", name: "Fusion", appleMusicID: "1110"),
            SubCategory(id: "jazz-latin", name: "Latin Jazz", appleMusicID: "1111"),
            SubCategory(id: "jazz-smooth", name: "Smooth Jazz", appleMusicID: "1114"),
        ]
    )

    // MARK: - Country

    static let country = GenreCategory(
        id: "country",
        name: "Country",
        appleMusicID: "6",
        subcategories: [
            SubCategory(id: "country-alternative", name: "Alternative Country", appleMusicID: "1033"),
            SubCategory(id: "country-americana", name: "Americana", appleMusicID: "1034"),
            SubCategory(id: "country-traditional", name: "Traditional Country", appleMusicID: "1042"),
            SubCategory(id: "country-contemporary", name: "Contemporary Country", appleMusicID: "1037"),
        ]
    )

    // MARK: - Classical

    static let classical = GenreCategory(
        id: "classical",
        name: "Classical",
        appleMusicID: "5",
        subcategories: [
            SubCategory(id: "classical-baroque", name: "Baroque Era", appleMusicID: "1018"),
            SubCategory(id: "classical-chamber", name: "Chamber Music", appleMusicID: "1019"),
            SubCategory(id: "classical-modern", name: "Modern Era", appleMusicID: "1027"),
            SubCategory(id: "classical-opera", name: "Opera", appleMusicID: "1028"),
            SubCategory(id: "classical-orchestral", name: "Orchestral", appleMusicID: "1029"),
        ]
    )

    // MARK: - Singer/Songwriter

    static let singerSongwriter = GenreCategory(
        id: "singer-songwriter",
        name: "Singer/Songwriter",
        appleMusicID: "10",
        subcategories: [
            SubCategory(id: "ss-alt-folk", name: "Alternative Folk", appleMusicID: "1062"),
            SubCategory(id: "ss-contemporary-folk", name: "Contemporary Folk", appleMusicID: "1063"),
            SubCategory(id: "ss-contemporary-ss", name: "Contemporary Singer/Songwriter", appleMusicID: "1064"),
            SubCategory(id: "ss-folk-rock", name: "Folk-Rock", appleMusicID: "1065"),
            SubCategory(id: "ss-new-acoustic", name: "New Acoustic", appleMusicID: "1066"),
            SubCategory(id: "ss-traditional-folk", name: "Traditional Folk", appleMusicID: "1067"),
        ]
    )

    // MARK: - Blues

    static let blues = GenreCategory(
        id: "blues",
        name: "Blues",
        appleMusicID: "2",
        subcategories: [
            SubCategory(id: "blues-acoustic", name: "Acoustic Blues", appleMusicID: "1210"),
            SubCategory(id: "blues-chicago", name: "Chicago Blues", appleMusicID: "1007"),
            SubCategory(id: "blues-classic", name: "Classic Blues", appleMusicID: "1009"),
            SubCategory(id: "blues-contemporary", name: "Contemporary Blues", appleMusicID: "1010"),
            SubCategory(id: "blues-country", name: "Country Blues", appleMusicID: "1011"),
            SubCategory(id: "blues-delta", name: "Delta Blues", appleMusicID: "1012"),
            SubCategory(id: "blues-electric", name: "Electric Blues", appleMusicID: "1013"),
        ]
    )

    // MARK: - Latin

    static let latin = GenreCategory(
        id: "latin",
        name: "Latin",
        appleMusicID: "12",
        subcategories: [
            SubCategory(id: "latin-urbano", name: "Urbano Latino", appleMusicID: "1119"),
            SubCategory(id: "latin-tropical", name: "Música Tropical", appleMusicID: "1124"),
            SubCategory(id: "latin-rock", name: "Rock y Alternativo", appleMusicID: "1121"),
            SubCategory(id: "latin-pop", name: "Pop Latino", appleMusicID: "1117"),
        ]
    )

    // MARK: - Soundtrack

    static let soundtrack = GenreCategory(
        id: "soundtrack",
        name: "Soundtrack",
        appleMusicID: "16",
        subcategories: [
            SubCategory(id: "soundtrack-foreign-cinema", name: "Foreign Cinema", appleMusicID: "1165"),
            SubCategory(id: "soundtrack-musicals", name: "Musicals", appleMusicID: "1166"),
            SubCategory(id: "soundtrack-original-score", name: "Original Score", appleMusicID: "1168"),
            SubCategory(id: "soundtrack-soundtrack", name: "Soundtrack", appleMusicID: "1169"),
            SubCategory(id: "soundtrack-tv", name: "TV Soundtrack", appleMusicID: "1172"),
        ]
    )
}
