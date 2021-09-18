class CompanyData {
  late String id;
  late String logoURL;
  late String name;
  late int state;
  late String address;
  late String homepageURL;

  //コンストラクタ
  CompanyData() {
    this.id = "";
    this.logoURL = "";
    this.name = "";
    this.state = 0;
    this.address = "";
    this.homepageURL = "";
  }

  CompanyData.Set(
      String id, String name, int state, String address, String homepageURL) {
    this.id = id;
    this.logoURL = "";
    this.name = name;
    this.state = state;
    this.address = address;
    this.homepageURL = homepageURL;
  }
}
