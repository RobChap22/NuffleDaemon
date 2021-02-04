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
    ""
  elsif a_question.match?(/^dodge$/i)
    ""
  elsif a_question.match?(/^defensive$/i)
    ""
  elsif a_question.match?(/^jump up$/i)
    ""
  elsif a_question.match?(/^leap$/i)
    ""
  elsif a_question.match?(/^safe pair of hands$/i)
    ""
  elsif a_question.match?(/^sidestep$/i)
    ""
  elsif a_question.match?(/^sneaky git$/i)
    ""
  elsif a_question.match?(/^sprint$/i)
    ""
  elsif a_question.match?(/^sure feet$/i)
    ""
  # General
  elsif a_question.match?(/^block$/i)
    ""
  elsif a_question.match?(/^dauntless$/i)
    ""
  elsif a_question.match?(/^dirty player$/i)
    ""
  elsif a_question.match?(/^fend$/i)
    ""
  elsif a_question.match?(/^frenzy$/i)
    ""
  elsif a_question.match?(/^kick$/i)
    ""
  elsif a_question.match?(/^pro$/i)
    ""
  elsif a_question.match?(/^shadowing$/i)
    ""
  elsif a_question.match?(/^strip ball$/i)
    ""
  elsif a_question.match?(/^sure hands$/i)
    ""
  elsif a_question.match?(/^tackle$/i)
    ""
  elsif a_question.match?(/^wrestle$/i)
    ""
  # Mutations
  elsif a_question.match?(/^big hand$/i)
    ""
  elsif a_question.match?(/^claws$/i)
    ""
  elsif a_question.match?(/^disturbing presence$/i)
    ""
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