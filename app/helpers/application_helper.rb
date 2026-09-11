module ApplicationHelper
  def flash_class(type)
    {
      "notice" => "alert-success",
      "alert" => "alert-error"
    }.fetch(type.to_s, "alert-info")
  end

  def user_initials(user)
    user.full_name.split.first(2).map { |name| name.first }.join.upcase
  end

  def daisyui_themes
    %w[light dark cupcake bumblebee emerald corporate synthwave retro cyberpunk
       valentine halloween garden forest aqua lofi pastel fantasy wireframe black
       luxury dracula cmyk autumn business acid lemonade night coffee winter dim
       nord sunset caramellatte abyss silk]
  end
end
