class User < ApplicationRecord

  has_many :microposts, dependent: :destroy

  has_many :active_relationships, class_name:  "Relationship",
  foreign_key: "follower_id",
  dependent:   :destroy

  has_many :passive_relationships, class_name:  "Relationship",
  foreign_key: "followed_id",
  dependent:   :destroy
  # フォローしているユーザー
  has_many :following, through: :active_relationships, source: :followed
  # フォローされているユーザー
  has_many :followers, through: :passive_relationships, source: :follower

  # cookiesの保存場所
  attr_accessor :remember_token
  
  # ActiveRecordのコールバックメソッド（before_save > DBに保存する前に呼ばれる）
  # before_save { self.email = email.downcase }
  before_save { email.downcase! }   #破壊的メソッド

  validates :name,  presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGE_ = /\A[\w+\-.]+@[a-z\d\-.]+               \.[a-z]+\z/i
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\- ]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX },
              uniqueness: { case_sensitive: false }

  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true


  ### クラスメソッド群 ###

  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # 試作feedの定義
  # 完全な実装は次章の「ユーザーをフォローする」を参照
  def feed
    # Micropost.where("user_id = ?", id)
    # Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id)
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
    
    # 演習問題14.3.2用
    # Micropost.where("user_id IN (?)", following_ids)  # フォローしているユーザーのみフィードに含める
    # Micropost.where("user_id = ?", id)                # 自分だけフィードに含める
    # Micropost.all                                     # フォローしていないユーザーも含めすべてをフィードに含める
  end

  # ユーザーをフォローする
  def follow(other_user)
    following << other_user
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end

end
