package computerdatabase

import scala.concurrent.duration._

import io.gatling.core.Predef._
import io.gatling.http.Predef._

object RMusic {

  val feeder = csv("music.csv").eager.random

  val rmusic = repeat(10, "n") {
    feed(feeder)
    .exec(http("RMusic ${n}")
      .get("/api/v1/music/${UUID}"))
      .pause(1)
  }

}

object CUser {

  val feeder = csv("users.csv").eager

  val cuser = repeat(4) {
    feed(feeder)
    .exec(http("CUser ${n}")
      .post("/api/v1/user/")
      .body(StringBody("{\"fname\": \"${fname}\", \"lname\": \"${lname}\", \"email\": \"${email}\"}")))
    .pause(1)
  }

}

object RUser {

  val feeder = csv("users.csv").eager.circular

  val ruser = repeat(4) {
    feed(feeder)
    .exec(http("RUser ${n}")
      .get("/api/v1/user/${UUID}"))
    .pause(1)
  }

}

class MusicSimulation extends Simulation {

  val httpProtocol = http
    .baseUrl("http://127.0.0.1:80")
    .acceptHeader("application/json,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .doNotTrackHeader("1")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")

  val httpProtocolS1 = http
    .baseUrl("http://127.0.0.1:80")
    .contentTypeHeader("application/json")
    .acceptHeader("application/json,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")


  val scnReadTables = scenario("ReadTables")
    .exec(RMusic.rmusic)
    .exec(RUser.ruser)

  val scn2 = scenario("UserCreate").exec(CUser.cuser)

  setUp(
    scnReadTables.inject(atOnceUsers(1))
  ).protocols(httpProtocol)
}