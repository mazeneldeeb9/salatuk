import SwiftUI

enum DhikrType: String, CaseIterable, Identifiable {
    // MARK: – Identifiable
    var id: String { rawValue }

    // MARK: –– الأقسام الرئيسية ––
    case morning     = "أذكار الصباح"
    case evening     = "أذكار المساء"
    case sleep       = "أذكار النوم"
    case awakening   = "أذكار الاستيقاظ"
    case alzakeer    = "جميع أذكار"
    case msb         = "المسبحة"
    case hasbzkat    = "حاسبة الزكاة"


    case gpsbosla    = "اتجاه القبلة"

    // MARK: –– الأدعية الرئيسية ––

    // MARK: –– فرعية: دعاء الغفران ––
    case ghofranDonub = "اول"
    case ghofranQulub = "ثاني"
    case ghofranMaal  = "ثالث"
    case ghofranMard  = "رابع"
    case ghofranSafar = "خامس"
    case ghofranAila  = "سادس"

    // MARK: –– فرعية: دعاء التوبة ––
    case tobaPerson  = "اول ت"
    case tobaChild   = "ثاني ت"
    case tobaFamily  = "ثالث ت"
    case tobaPatient = "رابع ت"
    case tobaTravel  = "خامس ت"
    case tobaSuccess = "سادس ت"

    // MARK: –– دعاء الاستغفار وفرعيّاته ––
    case adkarsl     = "الأدعية"



    case adkarsl1    = "أدعية من القرآن الكريم"
    case adkarsl2    = "دعاء لبس الثوب"
    case adkarsl3    = "دعاء لبس الثوب جديد"
    case adkarsl4    = "دعاء دخول الخلاء"


    case adkarsl5    = "دعاء الخروج من الخلاء"
    case adkarsl6    = "دعاء الذهاب الى المسجد"
    case adkarsl7    = "دعاء دخول المسجد"
    case adkarsl8    = "دعاء الخروج من المسجد"


    case adkarsl9    = "دعاء الاستفتاح"
    case adkarsl10    = "دعاء الركوع"
    case adkarsl11    = "دعاء الرفع من الركوع"
    case adkarsl12    = "دعاء السجود"


    case adkarsl13    = "دعاء الجلسة بين السجدتين"
    case adkarsl14    = "دعاء سجود التلاوة"
    case adkarsl15    = "الدعاء بعد التشهد الأخير قبل السلام"
    case adkarsl16    = "دعاء صلاة الاستخارة"


    case adkarsl17    = "الدعاء إذا تقلب ليلا"
    case adkarsl18    = "دعاء الفزع في النوم"
    case adkarsl19    = "دعاء قنوت الوتر"
    case adkarsl20    = "دعاء الهم والحزن"


    case adkarsl21    = "دعاء الكرب"
    case adkarsl22    = "دعاء لقاء العدو وذي السلطان"
    case adkarsl23    = "دعاء من خاف ظلم السلطان"
    case adkarsl24    = "الدعاء على العدو"


    case adkarsl25    = "دعاء من أصابه وسوسة في الإيمان"
    case adkarsl26    = "دعاء قضاء الدين"
    case adkarsl27    = "دعاء الوسوسة في الصلاة والقراءة"
    case adkarsl28    = "دعاء من استصعب عليه أمر"


    case adkarsl29    = "دعاء طرد الشيطان ووساوسه"
    case adkarsl30    = "الدعاء حينما يقع ما لا يرضاه أو غلب على أمره"
    case adkarsl31    = "الدعاء للمريض في عيادته"
    case adkarsl32    = "دعاء المريض الذي يئس من حياته"


    case adkarsl33    = "دعاء من أصيب بمصيبه"
    case adkarsl34    = "الدعاء عند إغماض الميت"
    case adkarsl35    = "الدعاء للميت في الصلاة عليه"
    case adkarsl36    = "الدعاء للفرط في الصلاة عليه"


    case adkarsl37    = "دعاء التعزية"
    case adkarsl38    = "الدعاء عند إدخال الميت القبر"
    case adkarsl39    = "الدعاء بعد دفن الميت"
    case adkarsl40    = "دعاء زيارة القبور"


    case adkarsl41    = "دعاء الريح"
    case adkarsl42    = "دعاء الرعد"
    case adkarsl43    = "من أدعية الاستسقاء"
    case adkarsl44    = "الدعاء إذا رأى المطر"


    case adkarsl45    = "من أدعية الاستصحاء"
    case adkarsl46    = "دعاء رؤية الهلال"
    case adkarsl47    = "الدعاء عند إفطار الصائم"
    case adkarsl48    = "الدعاء قبل الطعام"


    case adkarsl49    = "الدعاء عند الفراغ من الطعام"
    case adkarsl50    = "دعاء الضيف لصاحب الطعام"
    case adkarsl51    = "التعريض بالدعاء لطلب الطعام أو الشراب"
    case adkarsl52    = "الدعاء إذا أفطر عند أهل بيت"


    case adkarsl53    = "دعاء الصائم إذا حضر الطعام ولم يفطر"
    case adkarsl54    = "الدعاء عند رؤية باكورة الثمر"
    case adkarsl55    = "دعاء العطاس"
    case adkarsl56    = "الدعاء للمتزوج"


    case adkarsl57    = "دعاء المتزوج وشراء الدابة"
    case adkarsl58    = "الدعاء قبل إتيان الزوجة"
    case adkarsl59    = "دعاء الغضب"
    case adkarsl60    = "دعاء من رأى مبتلى"


    case adkarsl61    = "الدعاء لمن قال غفر الله لك"
    case adkarsl62    = "الدعاء لمن صنع إليك معروفا"
    case adkarsl63    = "الدعاء لمن قال إني أحبك في الله "
    case adkarsl64    = "الدعاء لمن عرض عليك ماله"


    case adkarsl65    = "الدعاء لمن أقرض عند القضاء"
    case adkarsl66    = "دعاء الخوف من الشرك"
    case adkarsl67    = "الدعاء لمن قال بارك الله فيك"
    case adkarsl68    = "دعاء كراهية الطيرة"


    case adkarsl69    = "دعاء الركوب"
    case adkarsl70    = "دعاء السفر"
    case adkarsl711    = "ذكر الرجوع من السفر"
    case adkarsl71    = "دعاء دخول القرية أو البلدة"
    case adkarsl72    = "دعاء دخول السوق"


    case adkarsl73    = "الدعاء إذا تعس المركوب"
    case adkarsl74    = "دعاء المسافر للمقيم"
    case adkarsl75    = "دعاء المقيم للمسافر"
    case adkarsl76    = "دعاء المسافر إذا أسحر"


    case adkarsl77    = "الدعاء إذا نزل منزلا في سفر أو غيره"
    case adkarsl78    = "الدعاء عند سماع صياح الديك ونهيق الحمار"
    case adkarsl79    = "الدعاء عند سماع نباح الكلاب بالليل"
    case adkarsl80    = "الدعاء لمن سببته"


    case adkarsl81    = "الدعاء بين الركن اليماني والحجر الأسود"
    case adkarsl82    = "دعاء الوقوف على الصفا و المروة"
    case adkarsl83    = "الدعاء يوم عرفة"
    case adkarsl84    = "دعاء من خشي أن يصيب شيئا بعينه"






    // MARK: –– أيقونات ––
    var icon: String {
        switch self {


        case .morning:   return "morningIcon"
        case .evening:   return "eveningIcon"
        case .sleep:     return "sleepIcon"
        case .awakening: return "awakeningIcon"
        case .alzakeer:  return "alzakeerIcon"
        case .msb:       return "msbhaIcon"
        case .hasbzkat:  return "hasbzkat"
        case .gpsbosla:  return "gpsbosla"
        case .ghofranDonub, .ghofranQulub, .ghofranMaal,
             .ghofranMard, .ghofranSafar, .ghofranAila:
                       return "f1"
        case .tobaPerson, .tobaChild, .tobaFamily,
             .tobaPatient, .tobaTravel, .tobaSuccess:
                       return "f1"
        case .adkarsl:   return "adkarsl"
        case .adkarsl1, .adkarsl2, .adkarsl3, .adkarsl4, .adkarsl5, .adkarsl6, .adkarsl7, .adkarsl8, .adkarsl9,
     .adkarsl10, .adkarsl11, .adkarsl12, .adkarsl13, .adkarsl14, .adkarsl15, .adkarsl16, .adkarsl17,
     .adkarsl18, .adkarsl19, .adkarsl20, .adkarsl21, .adkarsl22, .adkarsl23, .adkarsl24, .adkarsl25,
     .adkarsl26, .adkarsl27, .adkarsl28, .adkarsl29, .adkarsl30, .adkarsl31, .adkarsl32, .adkarsl33,
     .adkarsl34, .adkarsl35, .adkarsl36, .adkarsl37, .adkarsl38, .adkarsl39, .adkarsl40, .adkarsl41,
     .adkarsl42, .adkarsl43, .adkarsl44, .adkarsl45, .adkarsl46, .adkarsl47, .adkarsl48, .adkarsl49,
     .adkarsl50, .adkarsl51, .adkarsl52, .adkarsl53, .adkarsl54, .adkarsl55, .adkarsl56, .adkarsl57,
     .adkarsl58, .adkarsl59, .adkarsl60, .adkarsl61, .adkarsl62, .adkarsl63, .adkarsl64, .adkarsl65,
     .adkarsl66, .adkarsl67, .adkarsl68, .adkarsl69, .adkarsl70, .adkarsl711, .adkarsl71, .adkarsl72, .adkarsl73,
     .adkarsl74, .adkarsl75, .adkarsl76, .adkarsl77, .adkarsl78, .adkarsl79, .adkarsl80, .adkarsl81,
     .adkarsl82, .adkarsl83, .adkarsl84:
    return "adkarsl"
        }
    }

    // MARK: –– الألوان ––
    var color: Color {
        switch self {
        case .morning:   return .orange


        case .evening:   return .blue
        case .sleep:     return .purple
        case .awakening: return .green
        case .alzakeer:  return .blue
        case .msb, .hasbzkat, .gpsbosla:
                          return .pink
        case .ghofranDonub, .ghofranQulub, .ghofranMaal,
             .ghofranMard, .ghofranSafar, .ghofranAila:
                          return .purple
        case .tobaPerson, .tobaChild, .tobaFamily,
             .tobaPatient, .tobaTravel, .tobaSuccess:
                          return .pink
        case .adkarsl, .adkarsl1, .adkarsl2, .adkarsl3, .adkarsl4, .adkarsl5, .adkarsl6, .adkarsl7, .adkarsl8, .adkarsl9,
     .adkarsl10, .adkarsl11, .adkarsl12, .adkarsl13, .adkarsl14, .adkarsl15, .adkarsl16, .adkarsl17,
     .adkarsl18, .adkarsl19, .adkarsl20, .adkarsl21, .adkarsl22, .adkarsl23, .adkarsl24, .adkarsl25,
     .adkarsl26, .adkarsl27, .adkarsl28, .adkarsl29, .adkarsl30, .adkarsl31, .adkarsl32, .adkarsl33,
     .adkarsl34, .adkarsl35, .adkarsl36, .adkarsl37, .adkarsl38, .adkarsl39, .adkarsl40, .adkarsl41,
     .adkarsl42, .adkarsl43, .adkarsl44, .adkarsl45, .adkarsl46, .adkarsl47, .adkarsl48, .adkarsl49,
     .adkarsl50, .adkarsl51, .adkarsl52, .adkarsl53, .adkarsl54, .adkarsl55, .adkarsl56, .adkarsl57,
     .adkarsl58, .adkarsl59, .adkarsl60, .adkarsl61, .adkarsl62, .adkarsl63, .adkarsl64, .adkarsl65,
     .adkarsl66, .adkarsl67, .adkarsl68, .adkarsl69, .adkarsl70, .adkarsl711, .adkarsl71, .adkarsl72, .adkarsl73,
     .adkarsl74, .adkarsl75, .adkarsl76, .adkarsl77, .adkarsl78, .adkarsl79, .adkarsl80, .adkarsl81,
     .adkarsl82, .adkarsl83, .adkarsl84:
                          return .pink
        }
    }
}
