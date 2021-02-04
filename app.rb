# app.rb
require "sinatra"
require "json"
require "net/http"
require "uri"
require "tempfile"
require "line/bot"

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_ACCESS_TOKEN"]
  }
end

def bot_answer_to(a_question, user_name)

  # SKILLS

  # Agility
  if a_question.match?(/^catch$/i)
    "This player may re-roll a failed agility test when attempting to catch the ball."
  elsif a_question.match?(/^diving catch$/i)
    "This player may attempt to catch the ball if a pass, throw-in, or kick off causes it to land in a square within their Tackle Zone after scattering or deviating. This skill does not allow this player to attempt to catch the ball if it bounces into a square within their Tackle Zone.\n\nAdditionally, this player may apply a +1 modifier to any attempt to catch an accurate pass if they occupy the targeted square."
  elsif a_question.match?(/^diving tackle$/i)
    "Should an active opposition player that is attempting to Dodge, Jump, or Leap in order to vacate a square in which they are being Marked by this player pass their Agility test, you may declare that this player will use this Skill. Your opponent must immediately subtract 2 from the result of the Agility test. This player is then Placed Prone in the square vacated by the opposition player.\n\nIf the opposition player was being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^dodge$/i)
    "Once per team turn, during their activation, this player may re-roll a failed Agility test when attempting to Dodge.\n\nAdditionally, this player may choose to use this skill when they are the target of a Block action and a Stumble result is applied against them, as described on page 57."
  elsif a_question.match?(/^defensive$/i)
    "During your opponent\'s team turn (but not during your own team turn), any opposition players being Marked by this player cannot use the Guard skill."
  elsif a_question.match?(/^jump up$/i)
    "If this player is Prone they may stand up for free (i.e., standing up does not cost this player three (3) squares of Movement Allowance, as it normally would).\n\nAdditionally, if this player is Prone when activated, they may attempt to Jump Up and perform a Block action. This player makes an Agility test, applying a +1 modifier. If this test is passed, they stand up and may perform a Block action. If the test is failed, they remain Prone and their activation ends."
  elsif a_question.match?(/^leap$/i)
    "During their movement, instead of jumping over a single square that is occupied by a Prone or Stunned player, as described on page 45, a player with this Skill may choose to Leap over any single adjacent square, including unoccupied squares and squares occupied by Standing players.\n\nAdditionally, this player may reduce any negative modifier applied to the Agility test when they attempt to Jump over a Prone or Stunned player, or to Leap over an empty square or a square occupied by a Standing player by 1, to a minimum of -1.\n\nA player with this Skill cannot also have the Pogo Stick trait."
  elsif a_question.match?(/^safe pair of hands$/i)
    "If this player is Knocked Down or Placed Prone (but not if they Fall Over) whilst in possession of the ball, the ball does not bounce. Instead, you may place the ball in an unoccupied square adjacent to the one this player occupies when they become Prone."
  elsif a_question.match?(/^sidestep$/i)
    "If this player is pushed back for any reason, they are not moved into a square chosen by the opposing coach. Instead, you may choose any unoccupied square adjacent to this player. This player is pushed back into that square instead. If there are no unoccupied squares adjacent to this player, this Skill cannot be used."
  elsif a_question.match?(/^sneaky git$/i)
    "When this player performs a Foul action, they are not Sent-off for committing a Foul should they roll a natural double on the Armour roll.\n\nAdditionally, the activation of this player does not have to end once the foul has been committed. If you wish and if this player has not used their full Movement Allowance, they may continue to move after committing the Foul."
  elsif a_question.match?(/^sprint$/i)
    "When this player performs any action that includes movement, they may attempt to Rush three times, rather than the usual two."
  elsif a_question.match?(/^sure feet$/i)
    "Once per team turn, during their activation, this player may re-roll the D6 when attempting to Rush."
  # General
  elsif a_question.match?(/^block$/i)
    "When a Both Down result is applied during a Block action, this player may choose to ignore it and not get Knocked Down, as described on page 57."
  elsif a_question.match?(/^dauntless$/i)
    "When this player performs a Block action (on its own or as part of a Blitz action), if the nominated target has a higher Strength characteristic than this player before counting offensive or defensive assists but after applying any other modifiers, roll a D6 and add this player's Strength characteristic to the result. If the total is higher than the target\'s Strength characteristic, this player increases their Strength characteristic to be equal to that of the target of the Block action, before counting offensive or defensive assists, for the duration of this Block action.\n\nIf this player has another Skill that allows them to perform more than one Block action, such as Frenzy, they must make a Dauntless roll before each separate Block action is performed."
  elsif a_question.match?(/^dirty player$/i)
    "When this player commits a Foul action, either the Armour roll or Injury roll made against the victim may be modified by the amount shown in brackets. This modifier may be applied after the roll has been made."
  elsif a_question.match?(/^fend$/i)
    "If this player is pushed back as the result of any block dice result being applied against them, they may choose to prevent the player that pushed them back from following-up. However, the player that pushed them back may continue to move as part of a Blitz action if they have Movement Allowance remaining or by Rushing.\n\nThis Skill cannot be used when this player is chain-pushed, against a player with the Ball & Chain trait, or against a player with the Juggernaut skill that performed the Block action as part of a Blitz."
  elsif a_question.match?(/^frenzy$/i)
    "Every time this player performs a Block action (on its own or as part of a Blitz action), they must follow-up if the target is pushed back and if they are still able. If the target is still Standing after being pushed back, and if this player was able to follow-up, this player must then perform a second Block action against the same target, again following-up if the target is pushed back.\n\nIf this player is performing a Blitz action, performing a second Block action will also cost them one square of their Movement Allowance. If this player has no Movement Allowance left to perform a second Block action, they must Rush to do so. If they cannot Rush, they cannot perform a second Block action.\n\nNote that if an opposition player in possession of the ball is pushed back into your End Zone and is still standing, a touchdown will be scored, ending the drive. In this case, the second Block action is not performed.\n\nA player with this Skill cannot also have the Grab skill."
  elsif a_question.match?(/^kick$/i)
    "If this player is nominated to be the kicking player during a kick-off, you may choose to halve the result of the D6 to determine the number of squares that the ball deviates, rounding any fractions down."
  elsif a_question.match?(/^pro$/i)
    "During their activation, this player may attempt to re-roll one die. This die may have been rolled either as a single die roll or as part of a dice pool, but cannot be a die thet was rolled as part of an Armour, Injury, or Casualty roll. Roll a D6:\n\n- On a roll of 3+, the die can be re-rolled.\n\n- On a roll of 1 or 2, the die cannot be re-rolled.\n\nOnce this player has attempted to use this Skill, they may not use a re-roll from any other source to re-roll this one die."
  elsif a_question.match?(/^shadowing$/i)
    "This player can use this Skill when an opposition player they are Marking voluntarily moves out of a square within this player\'s Tackle Zone. Roll a D6, adding the MA of this player to the roll and then subtracting the MA of the opposition player. If the result is 6 or higher, or if the roll is a natural 6, this player may immediately move into the square vacated by the opposition player (this player does not need to Dodge to make this move). If, however, the result is 5 or lower, or if the roll is a natural 1, this Skill has no further effect.\n\nA player may use this Skill any number of times per turn, during either team\'s turn. If an opposition player is being Marked by more than one player with this Skill, only one player may use it."
  elsif a_question.match?(/^strip ball$/i)
    "When this player targets an opposition player that is in possession of the ball with a Block action (on its own or as part of a Blitz action), choosing to apply a Push Back result will cause that player to drop the ball in the square they are pushed back into. The ball will bounce from the square the player is pushed back into, as if they had been Knocked Down."
  elsif a_question.match?(/^sure hands$/i)
    "This player may re-roll any failed attempt to pick up the ball. In addition, the Strip Ball skill cannot be used against a player with this Skill."
  elsif a_question.match?(/^tackle$/i)
    "When an active opposition player attempts to Dodge from a square in which they were being Marked by one or more players on your team with this Skill, that player cannot use the Dodge skill.\n\nAdditionally, when an opposition player is targeted by a Block action performed by a player with this Skill, that player cannot use the Dodge skill if a Stumble result is applied against them."
  elsif a_question.match?(/^wrestle$/i)
    "This player may use this Skill when a Both Down result is applied, either when they perform a Block action or when they are the target of a Block action. Instead of applying the Both Down result as normal, and regardless of any other Skills either player may possess, both players are Placed Prone."
  # Mutations
  elsif a_question.match?(/^big hand$/i)
    "This player may ignore any modifier(s) for being Marked or for Pouring Rain weather conditions when they attempt to pick up the ball."
  elsif a_question.match?(/^claws$/i)
    "When you make an Armour roll against an opposition player that was Knocked Down as the result of a Block action performed by this player, a roll of 8+ before applying any modifiers will break their armour, regardless of their actual Armour Value."
  elsif a_question.match?(/^disturbing presence$/i)
    "When an opposition player performs either a Pass action, a Throw Team-mate action, or a Throw Bomb Special action, or attempts to either interfere with a pass or to catch the ball, they must apply a -1 modifier to the test for each player on your team with this Skill that is within three squares of them, even if the player with this Skill is Prone, Stunned, or has lost their Tackle Zone."
  elsif a_question.match?(/^extra arms$/i)
    ""
  elsif a_question.match?(/^foul appearance$/i)
    ""
  elsif a_question.match?(/^horns$/i)
    ""
  elsif a_question.match?(/^iron hard skin$/i)
    ""
  elsif a_question.match?(/^monstrous mouth$/i)
    ""
  elsif a_question.match?(/^prehensile tail$/i)
    ""
  elsif a_question.match?(/^tentacles$/i)
    ""
  elsif a_question.match?(/^two heads$/i)
    ""
  elsif a_question.match?(/^very long legs$/i)
    ""
  # Passing
  elsif a_question.match?(/^accurate$/i)
    ""
  elsif a_question.match?(/^cannoneer$/i)
    ""
  elsif a_question.match?(/^cloud burster$/i)
    ""
  elsif a_question.match?(/^dump(-| )off$/i)
    ""
  elsif a_question.match?(/^fumblerooskie$/i)
    ""
  elsif a_question.match?(/^hail mary pass$/i)
    ""
  elsif a_question.match?(/^leader$/i)
    ""
  elsif a_question.match?(/^nerves of steel$/i)
    ""
  elsif a_question.match?(/^on the ball$/i)
    ""
  elsif a_question.match?(/^pass$/i)
    ""
  elsif a_question.match?(/^running pass$/i)
    ""
  elsif a_question.match?(/^safe pass$/i)
    ""
  # Strength
  elsif a_question.match?(/^arm bar$/i)
    ""
  elsif a_question.match?(/^brawler$/i)
    ""
  elsif a_question.match?(/^break tackle$/i)
    ""
  elsif a_question.match?(/^grab$/i)
    ""
  elsif a_question.match?(/^guard$/i)
    ""
  elsif a_question.match?(/^juggernaut$/i)
    ""
  elsif a_question.match?(/^mighty blow$/i)
    ""
  elsif a_question.match?(/^multiple block$/i)
    ""
  elsif a_question.match?(/^pile driver$/i)
    ""
  elsif a_question.match?(/^stand firm$/i)
    ""
  elsif a_question.match?(/^strong arm$/i)
    ""
  elsif a_question.match?(/^thick skull$/i)
    ""

  # TRAITS
  elsif a_question.match?(/^animal savagery$/i)
    ""
  elsif a_question.match?(/^animosity$/i)
    ""
  elsif a_question.match?(/^always hungry$/i)
    ""
  elsif a_question.match?(/^ball (and|&) chain$/i)
    ""
  elsif a_question.match?(/^bombardier$/i)
    ""
  elsif a_question.match?(/^bone( |)head$/i)
    ""
  elsif a_question.match?(/^chainsaw$/i)
    ""
  elsif a_question.match?(/^decay$/i)
    ""
  elsif a_question.match?(/^hypnotic gaze$/i)
    ""
  elsif a_question.match?(/^kick team(-| |)mate$/i)
    ""
  elsif a_question.match?(/^loner$/i)
    ""
  elsif a_question.match?(/^no hands$/i)
    ""
  elsif a_question.match?(/^plague(-| )ridden$/i)
    ""
  elsif a_question.match?(/^pogo stick$/i)
    ""
  elsif a_question.match?(/^projectile vomit$/i)
    ""
  elsif a_question.match?(/^really stupid$/i)
    ""
  elsif a_question.match?(/^regeneration$/i)
    ""
  elsif a_question.match?(/^right stuff$/i)
    ""
  elsif a_question.match?(/^secret weapon$/i)
    ""
  elsif a_question.match?(/^stab$/i)
    ""
  elsif a_question.match?(/^stunty$/i)
    ""
  elsif a_question.match?(/^swarming$/i)
    ""
  elsif a_question.match?(/^swoop$/i)
    ""
  elsif a_question.match?(/^take root$/i)
    ""
  elsif a_question.match?(/^titchy$/i)
    ""
  elsif a_question.match?(/^timber$/i)
    ""
  elsif a_question.match?(/^throw team(-| |)mate$/i)
    ""
  elsif a_question.match?(/^unchannelled fury$/i)
    ""
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  # elsif a_question.match?(/^$/i)
  #   ""
  
  else
    ["I couldn't agree more.", "Great to hear that.", "Kinda make sense."].sample
  end
end

# def bot_jp_answer_to(a_question, user_name)
#   if a_question.match?(/(おはよう|こんにちは|こんばんは|ヤッホー|ハロー).*/)
#     "こんにちは#{user_name}さん！お元気ですか?"
#   elsif a_question.match?(/.*元気.*(？|\?｜か)/)
#     "私は元気です、#{user_name}さん"
#   elsif a_question.match?(/.*(le wagon|ワゴン|バゴン).*/i)
#     "#{user_name}さん... もしかして京都のLE WAGONプログラミング学校の話ですかね？ 素敵な画っこと思います！"
#   elsif a_question.end_with?('?','？')
#     "いい質問ですね、#{user_name}さん！"
#   else
#     ["そうですね！", "確かに！", "間違い無いですね！"].sample
#   end
# end

def send_bot_message(message, client, event)
  message_hash = { type: "text", text: message }
  client.reply_message(event["replyToken"], message_hash)

  # Log prints
  p 'Bot message sent!'
  p event["replyToken"]
  p message_hash
  p client
end

post "/callback" do
  body = request.body.read

  signature = request.env["HTTP_X_LINE_SIGNATURE"]
  unless client.validate_signature(body, signature)
    error 400 do "Bad Request" end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    p event
    # Focus on the message events (including text, image, emoji, vocal.. messages)
    return if event.class != Line::Bot::Event::Message

    case event.type
    # when receive a text message
    when Line::Bot::Event::MessageType::Text
      user_name = ""
      user_id = event["source"]["userId"]
      response = client.get_profile(user_id)
      if response.class == Net::HTTPOK
        contact = JSON.parse(response.body)
        p contact
        user_name = contact["displayName"]
      else
        # Can't retrieve the contact info
        p "#{response.code} #{response.body}"
      end

      # The answer mecanism is here!
      send_bot_message(
        bot_answer_to(event.message["text"], user_name),
        client,
        event
      )
    # when receive an image message
    when Line::Bot::Event::MessageType::Image
      response_image = client.get_message_content(event.message["id"])
      fetch_ibm_watson(response_image) do |image_results|
        # Sending the image results
        send_bot_message(
          "Looking at that picture, the first words that come to me are #{image_results[0..1].join(", ")} and #{image_results[2]}. Am I correct?",
          client,
          event
        )
      end
    end
  }
  "OK"
end