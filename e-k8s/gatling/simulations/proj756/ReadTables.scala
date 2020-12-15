package proj756

import scala.concurrent.duration._

import io.gatling.core.Predef._
import io.gatling.http.Predef._

object RMusic {

  val feeder = csv("music.csv").eager.random

  val rmusic = repeat(20, "i") {
    feed(feeder)
    .exec(http("RMusic ${i}")
      .get("/api/v1/music/${UUID}"))
      .pause(1)
  }

}

object RUser {

  val feeder = csv("users.csv").eager.circular

  val ruser = repeat(20, "i") {
    feed(feeder)
    .exec(http("RUser ${i}")
      .get("/api/v1/user/${UUID}"))
    .pause(1)
  }

}

class ReadTablesSim extends Simulation {

  val httpProtocol = http
    .baseUrl("http://127.0.0.1:80")
    .acceptHeader("application/json,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")

  val scnReadTables = scenario("ReadTables")
    .exec(RMusic.rmusic)
    .exec(RUser.ruser)

  setUp(
    scnReadTables.inject(atOnceUsers(1))
  ).protocols(httpProtocol)
}