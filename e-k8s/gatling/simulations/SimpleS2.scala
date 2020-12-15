package computerdatabase

import scala.concurrent.duration._

import io.gatling.core.Predef._
import io.gatling.http.Predef._

object Read {

  val read = repeat(5, "n") {
    exec(http("Read ${n}")
      .get("/api/v1/music/372bb8aa-eecb-482e-bc12-7dfec6080910"))
      .pause(1)
  }

}

object CUser {

  val feeder = csv("users.csv")

  val cuser = repeat(4) {
    feed(feeder)
    .exec(http("User")
      .post("/api/v1/user/")
      .body(StringBody("{\"fname\": \"${fname}\", \"lname\": \"${lname}\", \"email\": \"${email}\"}")))
      .pause(1)
  }

}

class MusicSimulation extends Simulation {

  val httpProtocol = http
    .baseUrl("http://127.0.0.1:30001")
    .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .doNotTrackHeader("1")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0")

  val httpProtocolS1 = http
    .baseUrl("http://127.0.0.1:80")
    .contentTypeHeader("application/json")
    .acceptHeader("application/json,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")


  val scn = scenario("MusicRead").exec(Read.read)
  /*
    .exec(http("request_1")
      .get("/api/v1/music/372bb8aa-eecb-482e-bc12-7dfec6080910"))
    .pause(1)
  */

  val scn2 = scenario("UserCreate").exec(CUser.cuser)

  setUp(
    scn2.inject(atOnceUsers(1))
  ).protocols(httpProtocolS1)
}