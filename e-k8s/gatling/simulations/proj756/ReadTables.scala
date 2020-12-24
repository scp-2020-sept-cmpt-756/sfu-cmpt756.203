package proj756

import scala.concurrent.duration._

import io.gatling.core.Predef._
import io.gatling.http.Predef._

object RMusic {

  val feeder = csv("music.csv").eager.random

  val rmusic = forever("i") {
    feed(feeder)
    .exec(http("RMusic ${i}")
      .get("/api/v1/music/${UUID}"))
      .pause(1)
  }

}

object RUser {

  val feeder = csv("users.csv").eager.circular

  val ruser = forever("i") {
    feed(feeder)
    .exec(http("RUser ${i}")
      .get("/api/v1/user/${UUID}"))
    .pause(1)
  }

}

/*
  Attempt to interleave reads from User and Music tables.
  The Gatling EDSL only honours the second (Music) read,
  ignoring the first read of User. [Shrug-emoji] 
 */
object RBoth {

  val u_feeder = csv("users.csv").eager.circular
  val m_feeder = csv("music.csv").eager.random

  val rboth = forever("i") {
    feed(u_feeder)
    .exec(http("RUser ${i}")
      .get("/api/v1/user/${UUID}"))
    .pause(1);

    feed(m_feeder)
    .exec(http("RMusic ${i}")
      .get("/api/v1/music/${UUID}"))
      .pause(1)
  }

}

class ReadTablesSim extends Simulation {

  val httpProtocol = http
    .baseUrl("http://127.0.0.1/")
    .acceptHeader("application/json,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    .authorizationHeader("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo")
    .acceptLanguageHeader("en-US,en;q=0.5")
}

class ReadUserSim extends ReadTablesSim {
  val scnReadUser = scenario("ReadUser")
      .exec(RUser.ruser)

  setUp(
    scnReadUser.inject(atOnceUsers(1))
  ).protocols(httpProtocol)
}

class ReadMusicSim extends ReadTablesSim {
  val scnReadMusic = scenario("ReadMusic")
    .exec(RMusic.rmusic)

  setUp(
    scnReadMusic.inject(atOnceUsers(1))
  ).protocols(httpProtocol)
}

/*
  This doesn't work---it just reads the Music table.
  We left it in here as possible inspiration for other work
  (or a warning that this approach will fail).
 */
class ReadBothSim extends ReadTablesSim {
  val scnReadBoth = scenario("ReadBoth")
    .exec(RBoth.rboth)

  setUp(
    scnReadBoth.inject(atOnceUsers(1))
  ).protocols(httpProtocol)
}
