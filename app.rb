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

  if a_question.match?(/^(assault|energy) shield$/i)
    "A d"
  elsif a_question.match?(/^BACKSTAB$/i)
    "If the attacker is not within the target’s vision arc, add 1 to the attack’s Strength."
  elsif a_question.match?(/^blaze$/i)
    "After an attack with the Blaze trait has been resolved, roll a D6 if the target was hit but not taken Out Of Action. On a 4, 5 or 6, they become subject to the Blaze condition.\n\nWhen activated, a fighter subject to the Blaze condition suffers an immediate Strength 3, AP -1, Damage 1 hit before acting as follows:\n\n- If Prone and Pinned the fighter immediately becomes Standing and Active and acts as described below.\n\n- If Standing and Active the fighter moves 2D6\" in a random direction, determined by the Scatter dice. The fighter will stop moving if this movement would bring them within 1\" of an enemy fighter or into base contact with impassable terrain. If this movement brings them within 1⁄2\" of the edge of a level or platform, they risk falling as described on page 29. If this movement takes the fighter beyond the edge of a level or platform, they will simply fall. At the end of this move, the fighter may choose to become Prone and Pinned. The fighter may then attempt to put the fire out.\n\n- If Standing and Engaged or Prone and Seriously Injured, the fighter does not move and attempts to put the fire out.\n\nTo attempt to put the fire out, roll a D6, adding 1 to the result for each other Active friendly fighter within 1\". On a result of 6 or more, the flames go out and the Blaze marker is removed. Pinned or Seriously Injured fighters add 2 to the result of the roll to see if the flames go out."
  elsif a_question.match?(/^burrowing$/i)
    "Burrowing weapons can be fired at targets o"
  else
    ["I couldn't agree more.", "Great to hear that.", "Kinda make sense."].sample
  end
end

def bot_jp_answer_to(a_question, user_name)
  if a_question.match?(/(おはよう|こんにちは|こんばんは|ヤッホー|ハロー).*/)
    "こんにちは#{user_name}さん！お元気ですか?"
  elsif a_question.match?(/.*元気.*(？|\?｜か)/)
    "私は元気です、#{user_name}さん"
  elsif a_question.match?(/.*(le wagon|ワゴン|バゴン).*/i)
    "#{user_name}さん... もしかして京都のLE WAGONプログラミング学校の話ですかね？ 素敵な画っこと思います！"
  elsif a_question.end_with?('?','？')
    "いい質問ですね、#{user_name}さん！"
  else
    ["そうですね！", "確かに！", "間違い無いですね！"].sample
  end
end

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
