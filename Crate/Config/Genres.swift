import Foundation

/// Static two-tier genre taxonomy with real Apple Music genre IDs.
///
/// Apple Music Genre IDs reference (parent genres):
///   20 = Alternative, 21 = Rock, 14 = Pop, 18 = Hip-Hop/Rap, 7 = Electronic,
///   17 = Dance, 15 = R&B/Soul, 10 = Singer/Songwriter, 11 = Jazz, 2 = Blues,
///   6 = Country, 24 = Reggae, 5 = Classical, 12 = Latin, 16 = Soundtrack
///
/// Sub-genre IDs verified against Apple's public genre API:
///   https://itunes.apple.com/WebObjects/MZStoreServices.woa/ws/genres?id={parentID}
enum Genres {

    static let all: [GenreCategory] = [
        rock,
        alternative,
        pop,
        hipHop,
        electronic,
        dance,
        rAndB,
        singerSongwriter,
        jazz,
        blues,
        country,
        reggae,
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
            SubCategory(id: "rock-american-trad", name: "American Trad Rock", appleMusicID: "1145"),
            SubCategory(id: "rock-arena", name: "Arena Rock", appleMusicID: "1146"),
            SubCategory(id: "rock-blues-rock", name: "Blues-Rock", appleMusicID: "1147"),
            SubCategory(id: "rock-british-invasion", name: "British Invasion", appleMusicID: "1148"),
            SubCategory(id: "rock-death-metal", name: "Death Metal/Black Metal", appleMusicID: "1149"),
            SubCategory(id: "rock-glam", name: "Glam Rock", appleMusicID: "1150"),
            SubCategory(id: "rock-hair-metal", name: "Hair Metal", appleMusicID: "1151"),
            SubCategory(id: "rock-hard", name: "Hard Rock", appleMusicID: "1152"),
            SubCategory(id: "rock-metal", name: "Metal", appleMusicID: "1153"),
            SubCategory(id: "rock-jam-bands", name: "Jam Bands", appleMusicID: "1154"),
            SubCategory(id: "rock-prog", name: "Prog-Rock/Art Rock", appleMusicID: "1155"),
            SubCategory(id: "rock-psychedelic", name: "Psychedelic", appleMusicID: "1156"),
            SubCategory(id: "rock-rock-and-roll", name: "Rock & Roll", appleMusicID: "1157"),
            SubCategory(id: "rock-rockabilly", name: "Rockabilly", appleMusicID: "1158"),
            SubCategory(id: "rock-roots", name: "Roots Rock", appleMusicID: "1159"),
            SubCategory(id: "rock-southern", name: "Southern Rock", appleMusicID: "1161"),
            SubCategory(id: "rock-surf", name: "Surf", appleMusicID: "1162"),
            SubCategory(id: "rock-tex-mex", name: "Tex-Mex", appleMusicID: "1163"),
        ]
    )

    // MARK: - Alternative

    static let alternative = GenreCategory(
        id: "alternative",
        name: "Alternative",
        appleMusicID: "20",
        subcategories: [
            SubCategory(id: "alt-college-rock", name: "College Rock", appleMusicID: "1001"),
            SubCategory(id: "alt-emo", name: "EMO", appleMusicID: "100018"),
            SubCategory(id: "alt-goth-rock", name: "Goth Rock", appleMusicID: "1002"),
            SubCategory(id: "alt-grunge", name: "Grunge", appleMusicID: "1003"),
            SubCategory(id: "alt-indie-pop", name: "Indie Pop", appleMusicID: "100020"),
            SubCategory(id: "alt-indie-rock", name: "Indie Rock", appleMusicID: "1004"),
            SubCategory(id: "alt-new-wave", name: "New Wave", appleMusicID: "1005"),
            SubCategory(id: "alt-pop-punk", name: "Pop Punk", appleMusicID: "100019"),
            SubCategory(id: "alt-punk", name: "Punk", appleMusicID: "1006"),
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
            SubCategory(id: "pop-oldies", name: "Oldies", appleMusicID: "1293"),
            SubCategory(id: "pop-pop-rock", name: "Pop/Rock", appleMusicID: "1133"),
            SubCategory(id: "pop-soft-rock", name: "Soft Rock", appleMusicID: "1134"),
            SubCategory(id: "pop-teen-pop", name: "Teen Pop", appleMusicID: "1135"),
        ]
    )

    // MARK: - Hip-Hop/Rap

    static let hipHop = GenreCategory(
        id: "hiphop",
        name: "Hip-Hop/Rap",
        appleMusicID: "18",
        subcategories: [
            SubCategory(id: "hiphop-alternative", name: "Alternative Rap", appleMusicID: "1068"),
            SubCategory(id: "hiphop-dirty-south", name: "Dirty South", appleMusicID: "1069"),
            SubCategory(id: "hiphop-east-coast", name: "East Coast Rap", appleMusicID: "1070"),
            SubCategory(id: "hiphop-gangsta", name: "Gangsta Rap", appleMusicID: "1071"),
            SubCategory(id: "hiphop-hardcore", name: "Hardcore Rap", appleMusicID: "1072"),
            SubCategory(id: "hiphop-hiphop", name: "Hip-Hop", appleMusicID: "1073"),
            SubCategory(id: "hiphop-latin", name: "Latin Rap", appleMusicID: "1074"),
            SubCategory(id: "hiphop-old-school", name: "Old School Rap", appleMusicID: "1075"),
            SubCategory(id: "hiphop-rap", name: "Rap", appleMusicID: "1076"),
            SubCategory(id: "hiphop-uk", name: "UK Hip-Hop", appleMusicID: "100016"),
            SubCategory(id: "hiphop-underground", name: "Underground Rap", appleMusicID: "1077"),
            SubCategory(id: "hiphop-west-coast", name: "West Coast Rap", appleMusicID: "1078"),
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

    // MARK: - Dance

    static let dance = GenreCategory(
        id: "dance",
        name: "Dance",
        appleMusicID: "17",
        subcategories: [
            SubCategory(id: "dance-breakbeat", name: "Breakbeat", appleMusicID: "1044"),
            SubCategory(id: "dance-exercise", name: "Exercise", appleMusicID: "1045"),
            SubCategory(id: "dance-garage", name: "Garage", appleMusicID: "1046"),
            SubCategory(id: "dance-hardcore", name: "Hardcore", appleMusicID: "1047"),
            SubCategory(id: "dance-house", name: "House", appleMusicID: "1048"),
            SubCategory(id: "dance-jungle-dnb", name: "Jungle/Drum'n'bass", appleMusicID: "1049"),
            SubCategory(id: "dance-techno", name: "Techno", appleMusicID: "1050"),
            SubCategory(id: "dance-trance", name: "Trance", appleMusicID: "1051"),
        ]
    )

    // MARK: - R&B/Soul

    static let rAndB = GenreCategory(
        id: "rnb",
        name: "R&B/Soul",
        appleMusicID: "15",
        subcategories: [
            SubCategory(id: "rnb-contemporary", name: "Contemporary R&B", appleMusicID: "1136"),
            SubCategory(id: "rnb-disco", name: "Disco", appleMusicID: "1137"),
            SubCategory(id: "rnb-doo-wop", name: "Doo Wop", appleMusicID: "1138"),
            SubCategory(id: "rnb-funk", name: "Funk", appleMusicID: "1139"),
            SubCategory(id: "rnb-motown", name: "Motown", appleMusicID: "1140"),
            SubCategory(id: "rnb-neo-soul", name: "Neo-Soul", appleMusicID: "1141"),
            SubCategory(id: "rnb-quiet-storm", name: "Quiet Storm", appleMusicID: "1142"),
            SubCategory(id: "rnb-soul", name: "Soul", appleMusicID: "1143"),
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

    // MARK: - Jazz

    static let jazz = GenreCategory(
        id: "jazz",
        name: "Jazz",
        appleMusicID: "11",
        subcategories: [
            SubCategory(id: "jazz-avant-garde", name: "Avant-Garde Jazz", appleMusicID: "1106"),
            SubCategory(id: "jazz-big-band", name: "Big Band", appleMusicID: "1052"),
            SubCategory(id: "jazz-bop", name: "Bop", appleMusicID: "1053"),
            SubCategory(id: "jazz-contemporary", name: "Contemporary Jazz", appleMusicID: "1107"),
            SubCategory(id: "jazz-cool", name: "Cool Jazz", appleMusicID: "1209"),
            SubCategory(id: "jazz-crossover", name: "Crossover Jazz", appleMusicID: "1108"),
            SubCategory(id: "jazz-dixieland", name: "Dixieland", appleMusicID: "1109"),
            SubCategory(id: "jazz-fusion", name: "Fusion", appleMusicID: "1110"),
            SubCategory(id: "jazz-hard-bop", name: "Hard Bop", appleMusicID: "1207"),
            SubCategory(id: "jazz-latin", name: "Latin Jazz", appleMusicID: "1111"),
            SubCategory(id: "jazz-mainstream", name: "Mainstream Jazz", appleMusicID: "1112"),
            SubCategory(id: "jazz-ragtime", name: "Ragtime", appleMusicID: "1113"),
            SubCategory(id: "jazz-smooth", name: "Smooth Jazz", appleMusicID: "1114"),
            SubCategory(id: "jazz-trad", name: "Trad Jazz", appleMusicID: "1208"),
            SubCategory(id: "jazz-vocal", name: "Vocal Jazz", appleMusicID: "1175"),
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

    // MARK: - Country

    static let country = GenreCategory(
        id: "country",
        name: "Country",
        appleMusicID: "6",
        subcategories: [
            SubCategory(id: "country-alternative", name: "Alternative Country", appleMusicID: "1033"),
            SubCategory(id: "country-americana", name: "Americana", appleMusicID: "1034"),
            SubCategory(id: "country-bluegrass", name: "Bluegrass", appleMusicID: "1035"),
            SubCategory(id: "country-contemporary-bluegrass", name: "Contemporary Bluegrass", appleMusicID: "1036"),
            SubCategory(id: "country-contemporary", name: "Contemporary Country", appleMusicID: "1037"),
            SubCategory(id: "country-gospel", name: "Country Gospel", appleMusicID: "1038"),
            SubCategory(id: "country-honky-tonk", name: "Honky Tonk", appleMusicID: "1039"),
            SubCategory(id: "country-outlaw", name: "Outlaw Country", appleMusicID: "1040"),
            SubCategory(id: "country-traditional-bluegrass", name: "Traditional Bluegrass", appleMusicID: "1041"),
            SubCategory(id: "country-traditional", name: "Traditional Country", appleMusicID: "1042"),
            SubCategory(id: "country-urban-cowboy", name: "Urban Cowboy", appleMusicID: "1043"),
        ]
    )

    // MARK: - Reggae

    static let reggae = GenreCategory(
        id: "reggae",
        name: "Reggae",
        appleMusicID: "24",
        subcategories: [
            SubCategory(id: "reggae-dub", name: "Dub", appleMusicID: "1193"),
            SubCategory(id: "reggae-lovers-rock", name: "Lovers Rock", appleMusicID: "100017"),
            SubCategory(id: "reggae-dancehall", name: "Modern Dancehall", appleMusicID: "1183"),
            SubCategory(id: "reggae-roots", name: "Roots Reggae", appleMusicID: "1192"),
            SubCategory(id: "reggae-ska", name: "Ska", appleMusicID: "1194"),
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
            SubCategory(id: "classical-choral", name: "Choral", appleMusicID: "1021"),
            SubCategory(id: "classical-crossover", name: "Classical Crossover", appleMusicID: "1022"),
            SubCategory(id: "classical-early", name: "Early Music", appleMusicID: "1023"),
            SubCategory(id: "classical-high", name: "High Classical", appleMusicID: "1211"),
            SubCategory(id: "classical-minimalism", name: "Minimalism", appleMusicID: "1026"),
            SubCategory(id: "classical-modern", name: "Modern Era", appleMusicID: "1027"),
            SubCategory(id: "classical-opera", name: "Opera", appleMusicID: "1028"),
            SubCategory(id: "classical-orchestral", name: "Orchestral", appleMusicID: "1029"),
            SubCategory(id: "classical-romantic", name: "Romantic Era", appleMusicID: "1031"),
        ]
    )

    // MARK: - Latin

    static let latin = GenreCategory(
        id: "latin",
        name: "Latin",
        appleMusicID: "12",
        subcategories: [
            SubCategory(id: "latin-baladas", name: "Baladas y Boleros", appleMusicID: "1120"),
            SubCategory(id: "latin-contemporary", name: "Contemporary Latin", appleMusicID: "1116"),
            SubCategory(id: "latin-mexicana", name: "Música Mexicana", appleMusicID: "1123"),
            SubCategory(id: "latin-tropical", name: "Música Tropical", appleMusicID: "1124"),
            SubCategory(id: "latin-pop", name: "Pop Latino", appleMusicID: "1117"),
            SubCategory(id: "latin-raices", name: "Raíces", appleMusicID: "1118"),
            SubCategory(id: "latin-rock", name: "Rock y Alternativo", appleMusicID: "1121"),
            SubCategory(id: "latin-urbano", name: "Urbano Latino", appleMusicID: "1119"),
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
            SubCategory(id: "soundtrack-video-game", name: "Video Game", appleMusicID: "100032"),
        ]
    )
}
