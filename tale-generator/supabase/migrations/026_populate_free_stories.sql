-- Migration 026: Populate free_stories table with sample stories
-- This script inserts 2 sample stories for each age category (2-3, 3-5, 5-7)

-- Insert stories for age category 2-3 (2 stories)
INSERT INTO tales.free_stories (title, content, age_category, language, is_active) VALUES
(
    'The Little Bunny''s Adventure',
    'Once upon a time, there was a little bunny named Fluffy. Fluffy loved to hop and play in the meadow. One sunny day, Fluffy found a beautiful flower. The flower was very special and sparkled in the sun. Fluffy showed the flower to all the other animals. They were so happy! Fluffy learned that sharing makes everyone smile.',
    '2-3',
    'en',
    true
),
(
    'Колобок',
    'Жил-был старик со старухой. Попросил старик испечь колобок. Старуха наскребла муки, замесила тесто и испекла колобок. Положила колобок на окошко остудиться. Колобок полежал-полежал, да и покатился с окошка на завалинку, с завалинки на травку, с травки на дорожку и покатился по дорожке. Встретил колобок зайца, волка, медведя, а от лисы не смог убежать. Колобок - это про то, что нужно слушаться родителей.',
    '2-3',
    'ru',
    true
);

-- Insert stories for age category 3-5 (2 stories)
INSERT INTO tales.free_stories (title, content, age_category, language, is_active) VALUES
(
    'The Magic Garden',
    'Emma was a curious little girl who loved flowers. One day, she discovered a secret garden behind her house. In the garden, there were magical flowers that could talk! The flowers told Emma wonderful stories about friendship and kindness. Emma visited the garden every day and learned many important lessons. She discovered that being kind to others makes the whole world brighter. The garden became her special place where she could always find happiness and friends.',
    '3-5',
    'en',
    true
),
(
    'Приключения Незнайки',
    'Жил-был Незнайка в Цветочном городе. Он был очень любопытным и всегда попадал в разные истории. Однажды Незнайка решил стать поэтом. Он написал стихи и прочитал их друзьям. Стихи были смешные, но друзья похвалили Незнайку за старание. Потом Незнайка захотел стать художником. Он нарисовал портреты всех своих друзей. Картины получились забавными, но все были рады. Незнайка понял, что самое главное - это дружба и поддержка друг друга.',
    '3-5',
    'ru',
    true
);

-- Insert stories for age category 5-7 (2 stories)
INSERT INTO tales.free_stories (title, content, age_category, language, is_active) VALUES
(
    'The Brave Little Knight',
    'Once upon a time in a faraway kingdom, there lived a young knight named Arthur. Arthur was smaller than the other knights, but he had the biggest heart. When a dragon started scaring the villagers, everyone was afraid. But Arthur knew that sometimes, being brave means asking for help and working together. He gathered all the villagers and they worked as a team. They discovered that the dragon was just lonely and wanted friends. Arthur showed kindness to the dragon, and soon they all became friends. The kingdom learned that courage and kindness together can solve any problem.',
    '5-7',
    'en',
    true
),
(
    'Сказка о дружбе',
    'В одном волшебном лесу жили разные звери. Белочка, зайчик и ёжик были лучшими друзьями. Они всегда помогали друг другу. Однажды зима была очень холодной, и зайчику нечего было есть. Белочка и ёжик решили помочь другу. Они собрали орехи, ягоды и коренья и отнесли их зайчику. Зайчик был очень благодарен. Весной, когда белочка потеряла свой домик, зайчик и ёжик помогли ей построить новый. Так друзья поняли, что настоящая дружба - это всегда быть рядом в трудную минуту и поддерживать друг друга.',
    '5-7',
    'ru',
    true
);

