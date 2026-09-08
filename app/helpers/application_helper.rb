module ApplicationHelper
  def flash_class(type)
    {
      "notice" => "alert-success",
      "success" => "alert-success",
      "alert" => "alert-error",
      "error" => "alert-error",
      "warning" => "alert-warning",
      "info" => "alert-info"
    }.fetch(type.to_s, "alert-info")
  end

  def daisyui_themes
    %w[light dark cupcake bumblebee emerald corporate synthwave retro cyberpunk
       valentine halloween garden forest aqua lofi pastel fantasy wireframe black
       luxury dracula cmyk autumn business acid lemonade night coffee winter dim
       nord sunset caramellatte abyss silk]
  end
end
