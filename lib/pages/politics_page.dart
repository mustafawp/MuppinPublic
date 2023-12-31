import 'package:flutter/material.dart';
import 'package:muppin_app/transactions/noscrolleffect.dart';

// ignore: camel_case_types
class politicsPage extends StatefulWidget {
  const politicsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _politicsPageState createState() => _politicsPageState();
}

// ignore: camel_case_types
class _politicsPageState extends State<politicsPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 40, 40, 42),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(154, 73, 47, 85),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              Image.asset(
                "assets/images/logo.png",
                width: 70,
                height: 100,
              ),
              const SizedBox(width: 8),
              const Text(
                "| Politikalar",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: ScrollConfiguration(
          behavior: NoGlowScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                buildSection(
                    "Sorumluluk Reddi Beyanı",
                    "Muppin, kullanıcıların kişisel verilerini, sohbet kayıtlarını ve diğer her bilgiyi korumak ve saklamak için mümkün olan her çabayı göstermiş olmakla birlikte; Muppin veya bağlantılı uygulamalarda olabilecek, belirtilmiş ya da ima edilmiş her türlü hata, eksiklik ya da amaç uyuşmazlığı ya da veri sızıntıları hususunda herhangi bir sorumluluğunun olmadığını ve bunlardan kaynaklanabilecek doğrudan ya da dolaylı zarar ve kayıplardan sorumlu tutulamayacağını beyan eder. Bu uygulamadaki, standartlardaki veya yasal yükümlülüklerdeki değişmeler sebebiyle yenilenebilir. Burada örnek olarak hesap açılmış bazı firma ya da ürünler tescilli marka olabilir ve/veya bağlı firmaların tescilli markaları olabilir ve Muppin 'in görüşlerini yansıtmayabilir.",
                    false),
                buildSection(
                    "Kullanım Koşulları",
                    "Muppin'e üye olan her kullanıcı, kullanım sözleşmesini kabul etmiştir. Bu sözleşmeyi, yalnızca Muppin değiştirebilir. Kullanım Koşullarının maddeleri aşağıdadır.",
                    false),
                buildSection(
                    "Madde 1: Gizlilik",
                    "Gizlilik, ayrı bir sayfada, kişisel verilerinizin tarafımızca işlenmesinin esaslarını düzenlemek üzere mevcuttur. Muppin'i kullandığınız takdirde, bu verilerin işlenmesinin gizlilik politikasına uygun olarak gerçekleştiğini kabul edersiniz.",
                    false),
                buildSection(
                    "Madde 2: Telif Hakları",
                    "Muppin'de yayınlanan tüm metin, kod, grafikler, logolar, resimler, ses dosyaları ve kullanılan yazılımın sahibi (bundan böyle ve daha sonra 'içerik' olarak anılacaktır) Muppin olup, tüm hakları saklıdır. Yazılı izin olmaksızın uygulama içeriğinin çoğaltılması veya kopyalanması kesinlikle yasaktır.",
                    false),
                buildSection(
                    "Genel Hükümler",
                    "Kullanıcıların tamamı, Muppin'i yalnızca hukuka uygun ve şahsi amaçlarla kullanacaklarını ve üçüncü kişinin haklarına tecavüz teşkil edecek nitelikteki herhangi bir faaliyette bulunmayacağını taahhüt eder. Muppin dâhilinde yaptıkları işlem ve eylemlerindeki, hukuki ve cezai sorumlulukları kendilerine aittir. İşbu iş ve eylemler sebebiyle, üçüncü kişilerin uğradıkları veya uğrayabilecekleri zararlardan dolayı Muppin'in doğrudan ve/veya dolaylı hiçbir sorumluluğu yoktur. ",
                    false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, String content, bool isLastSection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        if (!isLastSection) // Son bölüm değilse çizgiyi ekle
          const Divider(
            color: Color.fromARGB(154, 106, 94, 112),
            thickness: 5.0,
            height: 20.0,
          ),
      ],
    );
  }
}
